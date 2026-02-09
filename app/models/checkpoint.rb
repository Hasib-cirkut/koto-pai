class Checkpoint < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :chain
  belongs_to :created_by, class_name: "User"

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_not_exceed_outstanding, on: :create

  after_create_commit :apply_to_chain
  after_create_commit :broadcast_checkpoint

  private

  def amount_not_exceed_outstanding
    return if chain.blank?

    if amount.to_i > chain.outstanding.to_i
      errors.add(:amount, "cannot exceed outstanding balance")
    end
  end

  def apply_to_chain
    chain.with_lock do
      chain.reload
      new_outstanding = chain.outstanding - amount
      new_status = new_outstanding.zero? ? :closed : chain.status
      chain.update!(outstanding: new_outstanding, status: new_status)
    end
  end

  def broadcast_checkpoint
    broadcast_prepend_to chain,
                         target: dom_id(chain, :checkpoints),
                         partial: "checkpoints/checkpoint",
                         locals: { checkpoint: self, chain: chain }

    broadcast_replace_to chain,
                         target: dom_id(chain, :outstanding),
                         partial: "checkpoints/outstanding",
                         locals: { chain: chain }

    broadcast_replace_to chain,
                         target: dom_id(chain, :checkpoint_count),
                         partial: "checkpoints/count",
                         locals: { chain: chain }

    broadcast_replace_to chain,
                         target: dom_id(chain, :card),
                         partial: "chains/card",
                         locals: { chain: chain }
  end
end
