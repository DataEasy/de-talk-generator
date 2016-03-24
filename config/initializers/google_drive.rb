if Rails.configuration.detalk['google_drive']['active']
  msg_opt = []

  msg_opt << 'shared_folder:' unless Rails.configuration.detalk['google_drive']['shared_folder']
  msg_opt << 'service_account_json:' unless Rails.configuration.detalk['google_drive']['service_account_json']

  unless msg_opt.empty?
    msg = "When google drive integration is actived, you need to provide on config/detalk.yml:\n#{msg_opt.join("\n")}\n"
    Rails.logger.error msg
    raise msg
  end
end