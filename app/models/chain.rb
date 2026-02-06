class Chain < ApplicationRecord
  self.table_name = "chains"

  belongs_to :lender, class_name: "User", inverse_of: :lent_chains, optional: true
  belongs_to :borrower, class_name: "User", inverse_of: :borrowed_chains, optional: true
  belongs_to :creator, class_name: "User", inverse_of: :created_chains

  has_many :chain_participants, dependent: :destroy
  has_many :participants, through: :chain_participants, source: :user
  has_many :checkpoints, dependent: :destroy

  enum :status, { open: 0, closed: 1, archived: 2 }

  validates :lent_money, numericality: { only_integer: true, greater_than: 0 }
  validates :outstanding, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validate :lender_or_borrower_present

  before_validation :set_outstanding_cents, on: :create

  private

  def set_outstanding_cents
    self.outstanding ||= lent_money
    self.currency ||= "BDT"
  end

  def lender_or_borrower_present
    if lender_id.blank? && borrower_id.blank?
      errors.add(:base, "Lender or borrower must be present.")
    end
  end
end
