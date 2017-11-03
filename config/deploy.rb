set :application, 'imasquare'
set :repo_url, 'git@github.com:treby/imasquare.git'
set :branch, 'master'
set :deploy_to, '/var/www/vhosts/imasquare'
set :log_level, :debug
set :pty, true
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets bundle public/system public/assets)
set :default_env, { path: "/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH" }
set :unicorn_config_path, -> { File.join(current_path, "config", "unicorn", "#{fetch(:unicorn_rack_env)}.rb") }
set :keep_releases, 5

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end
end
