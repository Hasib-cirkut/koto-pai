class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :lent_chains, class_name: "Chain", foreign_key: :lender_id, inverse_of: :lender
  has_many :borrowed_chains, class_name: "Chain", foreign_key: :borrower_id, inverse_of: :borrower
  has_many :created_chains, class_name: "Chain", foreign_key: :creator_id, inverse_of: :creator

  has_many :chain_participants, dependent: :destroy
  has_many :participating_chains, through: :chain_participants, source: :chain
end
