class Checkpoint < ApplicationRecord
  belongs_to :chain
  belongs_to :created_by, class_name: "User"

  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validate :amount_not_exceed_outstanding, on: :create

  after_create_commit :apply_to_chain

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
end
