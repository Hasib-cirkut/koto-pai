class ChainPolicy < ApplicationPolicy
  def show?
    participant? || creator?
  end

  def update?
    creator?
  end

  def destroy?
    creator?
  end

  def add_participant?
    creator?
  end

  def add_checkpoint?
    creator? || lender? || borrower?
  end

  def approve_checkpoint?
    creator? || lender?
  end

  class Scope < Scope
    def resolve
      scope
        .left_joins(:chain_participants)
        .where(
          "chains.creator_id = :user_id OR chains.lender_id = :user_id OR chains.borrower_id = :user_id OR chain_participants.user_id = :user_id",
          user_id: user.id
        )
        .distinct
    end
  end

  private

  def participant?
    record.participants.exists?(user.id)
  end

  def creator?
    record.creator_id == user.id
  end

  def lender?
    record.lender_id == user.id
  end

  def borrower?
    record.borrower_id == user.id
  end
end
