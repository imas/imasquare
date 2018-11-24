class User < ApplicationRecord
  has_many :users_teams, dependent: :delete_all
  has_many :teams, through: :users_teams, source: :team
end
