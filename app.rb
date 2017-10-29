require 'mysql2-cs-bind'
require 'sinatra/base'
require 'omniauth-slack'

class Imasquare < Sinatra::Base
  use Rack::Session::Cookie
  use OmniAuth::Builder do
    provider :slack,
      ENV.fetch('IMASQUARE_SLACK_CLIENT_ID'),
      ENV.fetch('IMASQUARE_SLACK_CLIENT_SECRET'),
      scope: 'users:read,identify',
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
    set :session_secret, ENV.fetch('IMASQUARE_SESSION_SECRET', 'd1d_y0u_kN0w')
    enable :sessions
  end

  configure :development do
    require 'sinatra/reloader'
    require 'pry'
    register Sinatra::Reloader
  end

  get '/' do
    if current_user
      erb :index
    else
      erb :lp
    end
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
