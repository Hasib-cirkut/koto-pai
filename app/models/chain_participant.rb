class ChainParticipant < ApplicationRecord
  include ActionView::RecordIdentifier

  self.table_name = "chain_participants"

  belongs_to :chain, foreign_key: :chain_id, inverse_of: :chain_participants
  belongs_to :user

  enum :role, { lender: 0, borrower: 1, viewer: 2 }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :chain_id }

  after_create_commit :broadcast_participant_added
  after_create_commit :broadcast_chain_card_to_user
  after_destroy_commit :broadcast_participant_removed

  private

  def broadcast_participant_added
    broadcast_prepend_to chain,
                         target: dom_id(chain, :participants),
                         partial: "chain_participants/chain_participant",
                         locals: { chain_participant: self, chain: chain }
  end

  def broadcast_chain_card_to_user
    stream = "chains_user_#{user_id}"

    chain.broadcast_prepend_to(
      stream,
      target: "chains_list",
      partial: "chains/card",
      locals: { chain: chain }
    )

    chain.broadcast_remove_to(
      stream,
      target: "chains_empty"
    )
  end

  def broadcast_participant_removed
    return unless chain_id

    broadcast_remove_to [Chain, chain_id],
                        target: "chain_#{chain_id}_chain_participant_#{id}"
  end
end
