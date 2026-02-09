class ChainParticipantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chain

  def index
    @participants = @chain.chain_participants.includes(:user)
  end

  def create
    unless can_manage_participants?
      return redirect_to chain_path(@chain), alert: "You do not have permission to add participants."
    end

    email = params[:participant_email].to_s.strip.downcase
    if email.blank?
      return redirect_to chain_path(@chain), alert: "Participant email is required."
    end

    user = User.where("lower(email) = ?", email).first

    unless user
      return redirect_to chain_path(@chain), alert: "User not found."
    end

    participant = @chain.chain_participants.new(user: user, role: participant_role)

    if participant.save
      assign_counterparty_if_needed(user, participant.role)
      notify_participant_added(user)
      redirect_to chain_path(@chain), notice: "Participant added."
    else
      redirect_to chain_path(@chain), alert: participant.errors.full_messages.to_sentence
    end
  end

  def destroy
    unless can_manage_participants?
      return redirect_to chain_path(@chain), alert: "You do not have permission to remove participants."
    end

    participant = @chain.chain_participants.find(params[:id])
    participant.destroy
    redirect_to chain_path(@chain), notice: "Participant removed."
  end

  private

  def set_chain
    @chain = Chain.find(params[:chain_id])
  end

  def can_manage_participants?
    @chain.creator_id == current_user.id || @chain.lender_id == current_user.id
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
      title: "Added to chain",
      body: "#{current_user.email} added you to #{@chain.title.presence || "a chain"}.",
      chain_id: @chain.id
    )
  end

  def assign_counterparty_if_needed(user, role)
    case role.to_s
    when "lender"
      return if @chain.lender_id.present?
      @chain.update!(lender: user)
    when "borrower"
      return if @chain.borrower_id.present?
      @chain.update!(borrower: user)
    end
  end
end
