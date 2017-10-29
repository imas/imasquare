require 'mysql2-cs-bind'
require 'sinatra/base'
require 'omniauth-slack'

class Imasquare < Sinatra::Base
  use Rack::Session::Cookie,
    key: 'rack.session',
    expire_after: 60 * 60 * 24 * 14,
    secret: ENV.fetch('IMASQUARE_SESSION_SECRET', 'd1d_y0u_kN0w')
  use OmniAuth::Builder do
    provider :slack,
      ENV.fetch('IMASQUARE_SLACK_CLIENT_ID'),
      ENV.fetch('IMASQUARE_SLACK_CLIENT_SECRET'),
      scope: 'users:read,channels:write,identify',
      team: ENV.fetch('IMASQUARE_SLACK_TEAM_NAME', 'imas-hack')
  end

  helpers do
    def current_user
      if session[:user_id]
        @current_user ||= db.xquery(
          'SELECT id, nickname, avatar_url FROM users WHERE id = ?',
          session[:user_id]
        ).first
      end
    end

    def db
      @db_client ||= Mysql2::Client.new(
        host: ENV.fetch('IMASQUARE_DB_HOST', 'localhost'),
        port: ENV.fetch('IMASQUARE_DB_PORT', 3306),
        username: ENV.fetch('IMASQUARE_DB_USERNAME', 'root'),
        password: ENV.fetch('IMASQUARE_DB_PASSWORD', ''),
        database: ENV.fetch('IMASQUARE_DB_NAME', 'imasquare'),
        encoding: 'utf8mb4'
      )
    end
  end

  configure do
    enable :sessions
  end

  configure :development do
    require 'sinatra/reloader'
    require 'pry'
    register Sinatra::Reloader
  end

  get '/' do
    if current_user
      query = <<~SQL
        SELECT teams.id, teams.name, users.id AS leader_id, users.nickname AS leader_name FROM teams
        INNER JOIN users_teams AS ut ON teams.id = ut.team_id AND ut.role = 'leader'
        INNER JOIN users ON ut.user_id = users.id
      SQL
      @teams = db.query(query)
      erb :index
    else
      erb :lp
    end
  end

  get '/teams' do
    redirect '/', 303
  end

  get '/teams/new' do
    redirect('/', 303) unless current_user
    erb 'teams/new'.to_sym
  end

  post '/teams' do
    redirect('/', 303) unless current_user
    query = <<~SQL
      INSERT INTO teams (name, description, created_at, updated_at)
      VALUES (?, ?, NOW(), NOW())
    SQL
    db.xquery(query, params['name'], params['description'])
    team_id = db.last_id

    query = <<~SQL
      INSERT INTO users_teams (user_id, team_id, role, created_at, updated_at)
      VALUES (?, ?, "leader", NOW(), NOW())
    SQL
    db.xquery(query, current_user['id'], team_id)

    redirect("/teams/#{team_id}", 303)
  end

  get '/teams/:team_id' do
    query = <<~SQL
      SELECT teams.name, description, users.id AS leader_id, users.nickname AS leader_name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id AND ut.role = 'leader'
      INNER JOIN users ON ut.user_id = users.id
      WHERE teams.id = ?
    SQL

    @team = db.xquery(query, params['team_id']).first
    erb 'teams/show'.to_sym
  end

  get '/auth/slack/callback' do
    auth_info = request.env['omniauth.auth']['info']
    query = <<~SQL
      INSERT INTO users (id, nickname, avatar_url, created_at, updated_at)
      VALUES (?, ?, ?, NOW(), NOW())
      ON DUPLICATE KEY UPDATE nickname = ?, avatar_url = ?, updated_at = NOW()
    SQL
    db.xquery(query, auth_info['user_id'], auth_info['nickname'], auth_info['image_48'], auth_info['nickname'], auth_info['image_48'])
    session['user_id'] = auth_info['user_id']
    redirect '/', 303
  end

  get '/auth/slack/destroy' do
    session['user_id'] = nil
    redirect '/', 303
  end
end
