class TeamsController < ApplicationController
  def show
    @team = Team.find(params[:id])
    @members = @team.users
    @entries = @team.entries
  end

  def new
    @team = Team.new
  end

  def create
    team = current_user.teams.create(
      name: params[:name],
      description: params[:description],
      is_single: params[:is_single].to_i
    )
    current_user.users_teams.last.update(role: 'leader')

    redirect_to team_path(team)
  end
end
