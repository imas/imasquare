set :unicorn_rack_env, 'production'

role :app, [ENV['IMASQUARE_HOST']]
server ENV['IMASQUARE_HOST'], user: 'ec2-user', roles: %w(app)

set :ssh_options, {
  keys: %w(/Users/treby/.ssh/imasquare.pem),
  forward_agent: false,
  auth_methods: %w(publickey)
}
