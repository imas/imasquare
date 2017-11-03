require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/rbenv'
require 'capistrano/bundler'
require 'capistrano3/unicorn'
require 'capistrano/scm/git'

install_plugin Capistrano::SCM::Git

set :rbenv_type, :user
set :rbenv_ruby, '2.4.2'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }

# vim:ft=ruby
