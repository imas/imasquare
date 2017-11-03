set :unicorn_rack_env, 'production'

role :app, %w(ec2-52-197-19-202.ap-northeast-1.compute.amazonaws.com)
server 'ec2-52-197-19-202.ap-northeast-1.compute.amazonaws.com', user: 'ec2-user', roles: %w(app)

set :ssh_options, {
  keys: %w(/Users/treby/.ssh/imasquare.pem),
  forward_agent: false,
  auth_methods: %w(publickey)
}
