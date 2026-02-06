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

    user = User.find_by(email: params[:participant_email].to_s.downcase)

    unless user
      return redirect_to transaction_path(@transaction), alert: "User not found."
    end

    participant = @transaction.chain_participants.new(user: user, role: participant_role)

    if participant.save
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
end
