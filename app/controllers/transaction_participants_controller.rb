class TransactionParticipantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction

  def index
    @participants = @transaction.chain_participants.includes(:user)
  end

  def create
    unless can_manage_participants?
      return redirect_to transaction_path(@transaction), alert: "You do not have permission to add participants."
    end

    email = params[:participant_email].to_s.strip.downcase
    if email.blank?
      return redirect_to transaction_path(@transaction), alert: "Participant email is required."
    end

    user = User.where("lower(email) = ?", email).first

    unless user
      return redirect_to transaction_path(@transaction), alert: "User not found."
    end

    participant = @transaction.chain_participants.new(user: user, role: participant_role)

    if participant.save
      assign_counterparty_if_needed(user, participant.role)
      notify_participant_added(user)
      redirect_to transaction_path(@transaction), notice: "Participant added."
    else
      redirect_to transaction_path(@transaction), alert: participant.errors.full_messages.to_sentence
    end
  end

  def destroy
    unless can_manage_participants?
      return redirect_to transaction_path(@transaction), alert: "You do not have permission to remove participants."
    end

    participant = @transaction.chain_participants.find(params[:id])
    participant.destroy
    redirect_to transaction_path(@transaction), notice: "Participant removed."
  end

  private

  def set_transaction
    @transaction = Chain.find(params[:transaction_id])
  end

  def can_manage_participants?
    @transaction.creator_id == current_user.id || @transaction.lender_id == current_user.id
  end

  def participant_role
    role = params[:participant_role].to_s
    return :viewer unless ChainParticipant.roles.key?(role)

    role
  end

  def notify_participant_added(user)
    return if user == current_user

    NotificationsChannel.broadcast_to(
      user,
      title: "Added to transaction",
      body: "#{current_user.email} added you to #{@transaction.title.presence || "a transaction"}.",
      chain_id: @transaction.id
    )
  end

  def assign_counterparty_if_needed(user, role)
    case role.to_s
    when "lender"
      return if @transaction.lender_id.present?
      @transaction.update!(lender: user)
    when "borrower"
      return if @transaction.borrower_id.present?
      @transaction.update!(borrower: user)
    end
  end
end
