require 'constants'

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED do |name, start, finish, id, payload|
  if Rails.configuration.detalk['google_drive']['active']
    Rails.logger.debug("Enqueue CreateGoogleDriveFolderJob for talk: #{payload[:talk].title_formated}")
    CreateGoogleDriveFolderJob.perform_later(payload[:talk].id)
  end

  if Rails.configuration.detalk['slack']['active']
    Rails.logger.debug("Enqueue PublishNewTalkOnSlackJob for talk: #{payload[:talk].title_formated}")
    PublishNewTalkOnSlackJob.perform_later(payload[:talk].id)
  end
end

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_CANCELED do |name, start, finish, id, payload|
  if Rails.configuration.detalk['google_drive']['active']
    Rails.logger.debug("Enqueue DeleteGoogleDriveFolderJob for talk: #{payload[:talk].title_formated}")
    DeleteGoogleDriveFolderJob.perform_later(payload[:talk].id)
  end

  if Rails.configuration.detalk['slack']['active']
    Rails.logger.debug("Enqueue PublishTalkCanceledOnSlackJob for talk: #{payload[:talk].title_formated}")
    PublishTalkCanceledOnSlackJob.perform_later(payload[:talk].title_formated)
  end
end