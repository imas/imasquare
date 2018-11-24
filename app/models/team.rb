class Team < ApplicationRecord
  has_many :users_teams, dependent: :delete_all
  has_many :users, through: :users_teams, source: :user

  has_many :entries
end
