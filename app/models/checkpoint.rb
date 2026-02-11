class Checkpoint < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :chain
  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_not_exceed_outstanding, on: :create

  after_create_commit :handle_initial_status
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  scope :approved_or_pending, -> { where(status: [:approved, :pending]) }

  def approve!(user)
    return unless pending?

    update!(status: :approved, approved_by: user, approved_at: Time.current)
    apply_to_chain
    # broadcast_status_change is handled by after_update_commit callback
  end

  def reject!(user)
    return unless pending?

    update!(status: :rejected, approved_by: user, approved_at: Time.current)
    # broadcast_status_change is handled by after_update_commit callback
  end

  private

  def handle_initial_status
    # If created by lender/creator, auto-approve
    if created_by_id == chain.lender_id || created_by_id == chain.creator_id
      update_column(:status, :approved)
      update_column(:approved_by_id, created_by_id)
      update_column(:approved_at, Time.current)
      apply_to_chain
    end
    broadcast_new_checkpoint
  end

  def amount_not_exceed_outstanding
    return if chain.blank?

    # For borrowers submitting requests, validate against current outstanding
    # For lenders adding checkpoints, validate the same way
    if amount.to_i > chain.outstanding.to_i
      errors.add(:amount, "cannot exceed outstanding balance")
    end
  end

  def apply_to_chain
    return unless approved?

    chain.with_lock do
      chain.reload
      new_outstanding = chain.outstanding - amount
      new_status = new_outstanding.zero? ? :closed : chain.status
      chain.update!(outstanding: new_outstanding, status: new_status)
    end
  end

  def broadcast_new_checkpoint
    # Broadcast to each participant with personalized can_manage flag
    chain.participants.each do |user|
      can_manage = (user.id == chain.lender_id || user.id == chain.creator_id)
      Turbo::StreamsChannel.broadcast_prepend_to(
        [chain, user],
        target: dom_id(chain, :checkpoints),
        partial: "checkpoints/checkpoint",
        locals: { checkpoint: self, chain: chain, can_manage: can_manage }
      )
    end

    broadcast_chain_updates
  end

  def broadcast_status_change
    # Broadcast to each participant with personalized can_manage flag
    chain.participants.each do |user|
      can_manage = (user.id == chain.lender_id || user.id == chain.creator_id)
      Turbo::StreamsChannel.broadcast_replace_to(
        [chain, user],
        target: dom_id(chain, self),
        partial: "checkpoints/checkpoint",
        locals: { checkpoint: self, chain: chain, can_manage: can_manage }
      )
    end

    broadcast_chain_updates
  end

  def broadcast_chain_updates
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
