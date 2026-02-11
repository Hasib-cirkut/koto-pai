class CheckpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chain
  before_action :set_checkpoint, only: [:approve, :reject]

  def create
    authorize @chain, :add_checkpoint?

    @checkpoint = @chain.checkpoints.new(checkpoint_params.merge(created_by: current_user))

    if @checkpoint.save
      notify_parties_for_checkpoint(@checkpoint)
      redirect_to chain_path(@chain), notice: checkpoint_notice_message(@checkpoint)
    else
      flash.now[:alert] = @checkpoint.errors.full_messages.to_sentence
      @participant = ChainParticipant.new
      render "chains/show", status: :unprocessable_entity
    end
  end

  def approve
    authorize @chain, :approve_checkpoint?

    if @checkpoint.approve!(current_user)
      notify_checkpoint_approved(@checkpoint)
      redirect_to chain_path(@chain), notice: "Checkpoint approved."
    else
      redirect_to chain_path(@chain), alert: "Could not approve checkpoint."
    end
  end

  def reject
    authorize @chain, :approve_checkpoint?

    if @checkpoint.reject!(current_user)
      notify_checkpoint_rejected(@checkpoint)
      redirect_to chain_path(@chain), notice: "Checkpoint rejected."
    else
      redirect_to chain_path(@chain), alert: "Could not reject checkpoint."
    end
  end

  private

  def set_chain
    @chain = Chain.find(params[:chain_id])
  end

  def set_checkpoint
    @checkpoint = @chain.checkpoints.find(params[:id])
  end

  def checkpoint_params
    params.require(:checkpoint).permit(:amount, :note)
  end

  def checkpoint_notice_message(checkpoint)
    if checkpoint.pending?
      "Checkpoint requested and is pending approval."
    else
      "Checkpoint added."
    end
  end

  def notify_parties_for_checkpoint(checkpoint)
    recipients = checkpoint.chain.participants.to_a.uniq - [current_user]

    recipients.each do |user|
      ActionCable.server.broadcast(
        "notifications_user_#{user.id}",
        {
          title: checkpoint.pending? ? "Checkpoint requested" : "Payment recorded",
          body: "#{current_user.email} #{checkpoint.pending? ? 'requested' : 'recorded'} ৳#{checkpoint.amount} for #{@chain.title.presence || "a chain"}.",
          chain_id: @chain.id
        }
      )
    end
  end

  def notify_checkpoint_approved(checkpoint)
    return unless checkpoint.created_by

    ActionCable.server.broadcast(
      "notifications_user_#{checkpoint.created_by.id}",
      {
        title: "Checkpoint approved",
        body: "Your checkpoint request for ৳#{checkpoint.amount} has been approved.",
        chain_id: @chain.id
      }
    )
  end

  def notify_checkpoint_rejected(checkpoint)
    return unless checkpoint.created_by

    ActionCable.server.broadcast(
      "notifications_user_#{checkpoint.created_by.id}",
      {
        title: "Checkpoint rejected",
        body: "Your checkpoint request for ৳#{checkpoint.amount} has been rejected.",
        chain_id: @chain.id
      }
    )
  end
end
