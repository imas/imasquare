class EntriesController < ApplicationController
  def index
    @entries = Entry.all
  end

  def new
    @teams = current_user.teams
    redirect_to new_team_path if @teams.empty?
  end
end
