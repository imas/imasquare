Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack,
    ENV.fetch('IMASQUARE_SLACK_CLIENT_ID'),
    ENV.fetch('IMASQUARE_SLACK_CLIENT_SECRET'),
    scope: 'users:read,channels:write,identify',
    team: ENV.fetch('IMASQUARE_SLACK_TEAM_NAME', 'imas-hack')
end
