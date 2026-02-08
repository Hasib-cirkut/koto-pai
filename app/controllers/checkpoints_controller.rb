class CheckpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction

  def create
    unless @transaction.lender_id == current_user.id
      return redirect_to transaction_path(@transaction), alert: "Only the lender can add checkpoints."
    end

    @checkpoint = @transaction.checkpoints.new(checkpoint_params.merge(created_by: current_user))

    if @checkpoint.save
      notify_parties_for_checkpoint(@checkpoint)
      redirect_to transaction_path(@transaction), notice: "Checkpoint added."
    else
      flash.now[:alert] = @checkpoint.errors.full_messages.to_sentence
      @participant = ChainParticipant.new
      render "transactions/show", status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = Chain.find(params[:transaction_id])
  end

  def checkpoint_params
    params.require(:checkpoint).permit(:amount, :note)
  end

  private

  def notify_parties_for_checkpoint(checkpoint)

    recipients = checkpoint.chain.participants.to_a.uniq - [current_user]

    puts "Notifying recipients: #{recipients.map(&:email).join(', ')}"

    recipients.each do |user|
      NotificationsChannel.broadcast_to(
        user,
        title: "Payment recorded",
        body: "#{current_user.email} recorded ৳#{checkpoint.amount} for #{@transaction.title.presence || "a transaction"}.",
        chain_id: @transaction.id
      )
    end
  end
end
