class CheckpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chain

  def create
    authorize @chain, :add_checkpoint?

    @checkpoint = @chain.checkpoints.new(checkpoint_params.merge(created_by: current_user))

    if @checkpoint.save
      notify_parties_for_checkpoint(@checkpoint)
      redirect_to chain_path(@chain), notice: "Checkpoint added."
    else
      flash.now[:alert] = @checkpoint.errors.full_messages.to_sentence
      @participant = ChainParticipant.new
      render "chains/show", status: :unprocessable_entity
    end
  end

  private

  def set_chain
    @chain = Chain.find(params[:chain_id])
  end

  def checkpoint_params
    params.require(:checkpoint).permit(:amount, :note)
  end

  private

  def notify_parties_for_checkpoint(checkpoint)
    recipients = checkpoint.chain.participants.to_a.uniq - [current_user]

    recipients.each do |user|
      ActionCable.server.broadcast(
        "notifications_user_#{user.id}",
        {
          title: "Payment recorded",
          body: "#{current_user.email} recorded ৳#{checkpoint.amount} for #{@chain.title.presence || "a chain"}.",
          chain_id: @chain.id
        }
      )
    end
  end
end
