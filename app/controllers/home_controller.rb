class HomeController < ApplicationController
  def index
    @teams = Team.includes(:users).all
    @entries = Entry.all
  end

  def welcome
    return redirect_to home_path if logined?
    @users = User.all
  end
end
