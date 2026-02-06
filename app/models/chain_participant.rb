class ChainParticipant < ApplicationRecord
  self.table_name = "chain_participants"

  belongs_to :chain, foreign_key: :chain_id, inverse_of: :chain_participants
  belongs_to :user

  enum :role, { lender: 0, borrower: 1, viewer: 2 }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :chain_id }
end
