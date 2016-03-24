if Rails.configuration.detalk['slack']['active']
  Slack.configure do |config|
    config.token = Rails.configuration.detalk['slack']['token']
  end
end
