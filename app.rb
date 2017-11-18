require 'mysql2-cs-bind'
require 'sinatra/base'
require 'omniauth-slack'
require 'redcarpet'

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
    def markdown
      @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    end

    def current_user
      if session[:user_id]
        @current_user ||= db.xquery(
          'SELECT id, nickname, avatar_url FROM users WHERE id = ?',
          session[:user_id]
        ).first
      end
    end

    def logined?
      !current_user.nil?
    end

    def login_required!
      redirect('/', 303) unless logined?
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

  configure :production do
    use Rack::Auth::Basic do |username, password|
      username == 'imas' && password == 'saiko'
    end
  end

  configure :development do
    require 'sinatra/reloader'
    require 'pry'
    register Sinatra::Reloader
  end

  get '/' do
    redirect('/home', 303) if logined?

    @users = db.query('SELECT nickname, avatar_url FROM users')
    erb :index
  end

  get '/home' do
    query = <<~SQL
      SELECT teams.id, teams.name, users.id AS leader_id, users.nickname AS leader_name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id AND ut.role = 'leader'
      INNER JOIN users ON ut.user_id = users.id
    SQL
    @teams = db.query(query)

    query = <<~SQL
      SELECT teams.id AS team_id, users.id, users.nickname, users.avatar_url FROM users
      INNER JOIN users_teams AS ut ON users.id = ut.user_id
      INNER JOIN teams ON ut.team_id = teams.id
      WHERE teams.id IN (?)
    SQL
    team_member = db.xquery(query, @teams.map { |t| t['id'] })

    @teams.each do |team|
      team['members'] = team_member.select { |tm| tm['team_id'] == team['id'] }
    end

    query = <<~SQL
      SELECT
        entries.id, title,
        teams.id AS team_id, teams.name AS team_name,
        users.id AS author_id, users.nickname AS author_name, users.avatar_url
      FROM entries
      INNER JOIN teams ON teams.id = entries.team_id
      INNER JOIN users ON entries.author_id = users.id
    SQL
    @entries = db.query(query)
    erb :home
  end

  get '/users' do
    @users = db.xquery('SELECT id, nickname, avatar_url FROM users')
    erb '/users/index'.to_sym
  end

  get '/users/:user_id' do
    @user = db.xquery('SELECT id, nickname, avatar_url FROM users WHERE id = ? LIMIT 1', params['user_id']).first
    query = <<~SQL
      SELECT teams.id, teams.name, ut.role FROM users
      INNER JOIN users_teams AS ut ON users.id = ut.user_id
      INNER JOIN teams ON ut.team_id = teams.id
      WHERE users.id = ?
    SQL
    @user_teams = db.xquery(query, params['user_id'])
    erb 'users/show'.to_sym
  end

  get '/teams' do
    redirect '/', 303
  end

  get '/teams/new' do
    login_required!
    erb 'teams/new'.to_sym
  end

  post '/teams' do
    login_required!
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
      SELECT teams.id, teams.name, description, users.id AS leader_id, users.nickname AS leader_name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id AND ut.role = 'leader'
      INNER JOIN users ON ut.user_id = users.id
      WHERE teams.id = ?
    SQL

    @team = db.xquery(query, params['team_id']).first

    query = <<~SQL
      SELECT users.id, users.nickname, users.avatar_url, ut.role FROM users_teams AS ut
      INNER JOIN users ON ut.user_id = users.id
      WHERE ut.team_id = ?
    SQL

    @members = db.xquery(query, params['team_id'])

    query = <<~SQL
      SELECT entries.id, entries.title, users.id AS author_id, users.nickname AS author_name, users.avatar_url FROM entries
      INNER JOIN users ON entries.author_id = users.id
      WHERE entries.team_id = ?
    SQL

    @entries = db.xquery(query, params['team_id'])

    erb 'teams/show'.to_sym
  end

  post '/teams/:team_id/join' do
    login_required!
    query = <<~SQL
      SELECT users.id, users.nickname, ut.team_id, ut.role FROM users_teams AS ut
      INNER JOIN users ON ut.user_id = users.id
      WHERE ut.team_id = ?
    SQL

    members = db.xquery(query, params['team_id'])
    unless members.map { |m| m['id'] }.include?(current_user['id'])
      query = <<~SQL
        INSERT INTO users_teams (user_id, team_id, role, created_at, updated_at)
        VALUES (?, ?, "member", NOW(), NOW())
      SQL
      db.xquery(query, current_user['id'], params['team_id'])
    end

    redirect("/teams/#{members.first['team_id']}", 303)
  end

  get '/teams/:team_id/leave' do
    login_required!
    query = <<~SQL
      SELECT users.id, users.nickname, ut.team_id, ut.role FROM users_teams AS ut
      INNER JOIN users ON ut.user_id = users.id
      WHERE ut.team_id = ?
    SQL
    members = db.xquery(query, params['team_id'])
    ut = members.find { |m| m['id'] == current_user['id'] }
    return 403 if ut['role'] == 'leader'

    query = <<~SQL
      DELETE FROM users_teams WHERE user_id = ? AND team_id = ?
    SQL
    db.xquery(query, current_user['id'], params['team_id'])
    redirect("/teams/#{params['team_id']}", 303)
  end

  get '/teams/:team_id/edit' do
    login_required!
    query = <<~SQL
      SELECT teams.id, teams.name, description, users.id AS leader_id, users.nickname AS leader_name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id AND ut.role = 'leader'
      INNER JOIN users ON ut.user_id = users.id
      WHERE teams.id = ?
    SQL
    @team = db.xquery(query, params['team_id']).first

    return 403 if @team['leader_id'] != current_user['id']
    erb 'teams/edit'.to_sym
  end

  post '/teams/:team_id' do
    login_required!

    ut = db.xquery('SELECT user_id FROM users_teams WHERE team_id = ? AND role = "leader"', params['team_id']).first
    return 403 if ut['user_id'] != current_user['id']

    db.xquery('UPDATE teams SET name = ?, description = ?, updated_at = NOW() WHERE id = ?', params['name'], params['description'], params['team_id'])
    redirect("/teams/#{params['team_id']}", 303)
  end

  get '/teams/:team_id/entries/new' do
    login_required!

    query = <<~SQL
      SELECT teams.id, name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id
      WHERE teams.id = ? AND ut.user_id = ?
    SQL
    @team = db.xquery(query, params['team_id'], current_user['id']).first

    if @team
      erb 'entries/new'.to_sym
    else
      redirect '/', 403
    end
  end

  post '/teams/:team_id/entries' do
    login_required!

    query = <<~SQL
      SELECT teams.id, name FROM teams
      INNER JOIN users_teams AS ut ON teams.id = ut.team_id
      WHERE teams.id = ? AND ut.user_id = ?
    SQL
    @team = db.xquery(query, params['team_id'], current_user['id']).first

    unless @team
      redirect '/', 403
      return
    end

    query = <<~SQL
      INSERT INTO entries (author_id, team_id, title, summary, created_at, updated_at)
      VALUES (?, ?, ?, ?, NOW(), NOW())
    SQL
    db.xquery(query, current_user['id'], params['team_id'], params['title'], params['summary'])
    entry_id = db.last_id
    redirect("/entries/#{entry_id}", 303)
  end

  get '/entries/:entry_id' do
    query = <<~SQL
      SELECT entries.id AS entry_id, entries.title, entries.summary,
      users.id AS author_id, users.nickname AS author_name, users.avatar_url,
      teams.id AS team_id, teams.name AS team_name FROM entries
      INNER JOIN users ON entries.author_id = users.id
      INNER JOIN teams ON entries.team_id = teams.id
      WHERE entries.id = ?
    SQL

    @entry = db.xquery(query, params['entry_id']).first
    erb 'entries/show'.to_sym
  end

  get '/entries/:entry_id/edit' do
    login_required!

    query = <<~SQL
      SELECT entries.id, entries.title, entries.summary, users.id AS author_id, teams.id AS team_id, teams.name AS team_name
      FROM entries
      INNER JOIN users ON entries.author_id = users.id
      INNER JOIN teams ON entries.team_id = teams.id
      WHERE entries.id = ?
    SQL
    @entry = db.xquery(query, params['entry_id']).first
    return redirect("/entries/#{@entry['id']}", 403) unless current_user['id'] == @entry['author_id']

    erb 'entries/edit'.to_sym
  end

  post '/entries/:entry_id' do
    login_required!

    query = <<~SQL
      SELECT entries.id, entries.title, entries.summary, users.id AS author_id
      FROM entries INNER JOIN users ON entries.author_id = users.id WHERE entries.id = ?
    SQL
    entry = db.xquery(query, params['entry_id']).first
    return redirect("/entries/#{entry['id']}", 403) unless current_user['id'] == entry['author_id']

    db.xquery('UPDATE entries SET title = ?, summary = ?, updated_at = NOW() WHERE id = ?', params['title'], params['summary'], params['entry_id'])
    redirect("/entries/#{entry['id']}", 303)
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
    session.clear
    redirect '/', 303
  end
end
