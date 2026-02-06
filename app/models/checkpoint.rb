class Checkpoint < ApplicationRecord
  belongs_to :chain
  belongs_to :created_by, class_name: "User"

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_not_exceed_outstanding, on: :create

  after_create_commit :apply_to_chain

  private

  def amount_not_exceed_outstanding
    return if chain.blank?

    if amount_cents.to_i > chain.outstanding_cents.to_i
      errors.add(:amount_cents, "cannot exceed outstanding balance")
    end
  end

  def apply_to_chain
    chain.with_lock do
      chain.reload
      new_outstanding = chain.outstanding_cents - amount_cents
      new_status = new_outstanding.zero? ? :closed : chain.status
      chain.update!(outstanding_cents: new_outstanding, status: new_status)
    end
  end
end
