class CheckpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction

  def create
    unless @transaction.lender_id == current_user.id
      return redirect_to transaction_path(@transaction), alert: "Only the lender can add checkpoints."
    end

    @checkpoint = @transaction.checkpoints.new(checkpoint_params.merge(created_by: current_user))

    if @checkpoint.save
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
    params.require(:checkpoint).permit(:amount_cents, :note)
  end
end
