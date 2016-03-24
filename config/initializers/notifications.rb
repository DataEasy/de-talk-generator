require 'constants'

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_PUBLISHED do |name, start, finish, id, payload|
  Rails.logger.debug("Enqueue CreateGoogleDriveFolderJob for talk: #{payload[:talk_id]}")
  CreateGoogleDriveFolderJob.perform_now(payload[:talk_id])

  Rails.logger.debug("Enqueue PublishNewTalkOnSlackJob for talk: #{payload[:talk_id]}")
  PublishNewTalkOnSlackJob.perform_now(payload[:talk_id])
end

ActiveSupport::Notifications.subscribe Detalk::Constants::NOTIFICATIONS_TALK_CANCELED do |name, start, finish, id, payload|
  Rails.logger.debug("Enqueue DeleteGoogleDriveFolderJob for talk: #{payload[:talk_id]}")
  DeleteGoogleDriveFolderJob.perform_now(payload[:talk_id])

  Rails.logger.debug("Enqueue PublishTalkCanceledOnSlackJob for talk: #{payload[:talk_id]}")
  PublishTalkCanceledOnSlackJob.perform_now(payload[:talk_id])
end