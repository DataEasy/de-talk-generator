require 'constants'

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED do |name, start, finish, id, payload|
  Rails.logger.debug("Enqueue CreateGoogleDriveFolderJob for talk: #{payload[:talk_id]}")
  CreateGoogleDriveFolderJob.perform_later(payload[:talk_id])
end

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_CANCELED do |name, start, finish, id, payload|
  Rails.logger.debug("Enqueue DeleteGoogleDriveFolderJob for talk: #{payload[:talk_id]}")
  DeleteGoogleDriveFolderJob.perform_later(payload[:talk_id])
end