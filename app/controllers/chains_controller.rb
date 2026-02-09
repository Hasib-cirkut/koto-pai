class ChainsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chain, only: [:show, :history, :update, :destroy]

  def index
    @chains = policy_scope(Chain)
      .order(created_at: :desc)
      .limit(5)
  end

  def new
    @chain = Chain.new
  end

  def create
    role = params[:current_user_role].to_s
    counterparty_email = params[:counterparty_email].to_s.downcase
    counterparty = counterparty_email.present? ? User.find_by(email: counterparty_email) : nil

    if counterparty_email.present? && counterparty.nil?
      @chain = Chain.new(chain_params)
      flash.now[:alert] = "Counterparty email was not found."
      return render :new, status: :unprocessable_entity
    end

    lender, borrower = if role == "lender"
      [current_user, counterparty]
    else
      [counterparty, current_user]
    end

    @chain = Chain.new(chain_params.merge(
      lender: lender,
      borrower: borrower,
      creator: current_user
    ))

    if @chain.save
      ChainParticipant.create!(chain: @chain, user: lender, role: :lender) if lender
      ChainParticipant.create!(chain: @chain, user: borrower, role: :borrower) if borrower
      notify_participants_new_chain
      broadcast_new_chain_card

      redirect_to chain_path(@chain), notice: "Chain created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @chain, :show?
    @checkpoint = @chain.checkpoints.new
    @participant = ChainParticipant.new
  end

  def history
    authorize @chain, :show?
    @checkpoints = @chain.checkpoints.order(created_at: :desc)
  end

  def destroy
    authorize @chain, :destroy?

    @chain.destroy
    redirect_to chains_path, notice: "Chain deleted."
  end

  def update
    authorize @chain, :update?

    if @chain.update(chain_params)
      redirect_to chain_path(@chain), notice: "Chain updated."
    else
      flash.now[:alert] = @chain.errors.full_messages.to_sentence
      @checkpoint = @chain.checkpoints.new
      @participant = ChainParticipant.new
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_chain
    @chain = Chain.find_by(id: params[:id])
    return if @chain

    redirect_to chains_path, alert: "Chain not found."
  end

  def chain_params
    params.require(:chain).permit(:title, :description, :lent_money, :currency)
  end

  def notify_participants_new_chain
    recipients = (@chain.participants.to_a + [@chain.creator]).compact.uniq - [current_user]

    recipients.each do |user|
      ActionCable.server.broadcast(
        "notifications_user_#{user.id}",
        {
          title: "New chain",
          body: "#{current_user.email} created #{@chain.title.presence || "a chain"}.",
          chain_id: @chain.id
        }
      )
    end
  end

  def broadcast_new_chain_card
    recipients = (@chain.participants.to_a + [@chain.creator]).compact.uniq

    recipients.each do |user|
      stream = "chains_user_#{user.id}"
      @chain.broadcast_prepend_to(
        stream,
        target: "chains_list",
        partial: "chains/card",
        locals: { chain: @chain }
      )

      @chain.broadcast_remove_to(
        stream,
        target: "chains_empty"
      )
    end
  end
end
