class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:show, :history, :update, :destroy]

  def index
    user_id = current_user.id
    @transactions = Chain
      .left_joins(:chain_participants)
      .where(
        "chains.lender_id = :user_id OR chains.borrower_id = :user_id OR chain_participants.user_id = :user_id",
        user_id: user_id
      )
      .distinct
      .order(created_at: :desc)
      .limit(5)
  end

  def new
    @transaction = Chain.new
  end

  def create
    role = params[:current_user_role].to_s
    counterparty_email = params[:counterparty_email].to_s.downcase
    counterparty = counterparty_email.present? ? User.find_by(email: counterparty_email) : nil

    if counterparty_email.present? && counterparty.nil?
      @transaction = Chain.new(transaction_params)
      flash.now[:alert] = "Counterparty email was not found."
      return render :new, status: :unprocessable_entity
    end

    lender, borrower = if role == "lender"
      [current_user, counterparty]
    else
      [counterparty, current_user]
    end

    @transaction = Chain.new(transaction_params.merge(
      lender: lender,
      borrower: borrower,
      creator: current_user
    ))

    if @transaction.save
      ChainParticipant.create!(chain: @transaction, user: lender, role: :lender) if lender
      ChainParticipant.create!(chain: @transaction, user: borrower, role: :borrower) if borrower
      notify_participants_new_transaction
      broadcast_new_transaction_card

      redirect_to transaction_path(@transaction), notice: "Transaction created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @checkpoint = @transaction.checkpoints.new
    @participant = ChainParticipant.new
  end

  def history
    @checkpoints = @transaction.checkpoints.order(created_at: :desc)
  end

  def destroy
    unless @transaction.creator_id == current_user.id
      return redirect_to transaction_path(@transaction), alert: "Only the creator can delete this transaction."
    end

    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction deleted."
  end

  def update
    unless @transaction.creator_id == current_user.id
      return redirect_to transaction_path(@transaction), alert: "Only the creator can update this transaction."
    end

    if @transaction.update(transaction_params)
      redirect_to transaction_path(@transaction), notice: "Transaction updated."
    else
      flash.now[:alert] = @transaction.errors.full_messages.to_sentence
      @checkpoint = @transaction.checkpoints.new
      @participant = ChainParticipant.new
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = Chain.find_by(id: params[:id])
    return if @transaction

    redirect_to transactions_path, alert: "Transaction not found."
  end

  def transaction_params
    key = params[:transaction].present? ? :transaction : :chain
    params.require(key).permit(:title, :description, :lent_money, :currency)
  end

  def notify_participants_new_transaction
    recipients = (@transaction.participants.to_a + [@transaction.creator]).compact.uniq - [current_user]

    recipients.each do |user|
      NotificationsChannel.broadcast_to(
        user,
        title: "New transaction",
        body: "#{current_user.email} created #{@transaction.title.presence || "a transaction"}.",
        chain_id: @transaction.id
      )
    end
  end

  def broadcast_new_transaction_card
    recipients = (@transaction.participants.to_a + [@transaction.creator]).compact.uniq

    recipients.each do |user|
      stream = "transactions_user_#{user.id}"
      @transaction.broadcast_prepend_to(
        stream,
        target: "transactions_list",
        partial: "transactions/card",
        locals: { transaction: @transaction }
      )

      @transaction.broadcast_remove_to(
        stream,
        target: "transactions_empty"
      )
    end
  end
end
