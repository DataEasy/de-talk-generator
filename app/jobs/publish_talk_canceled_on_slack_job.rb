class PublishTalkCanceledOnSlackJob < ActiveJob::Base
  queue_as :default

  def perform(talk_title_formated)
    Rails.logger.debug("Publishing talk canceled on slack: #{talk_title_formated}")

    SlackService.new.send_detalk_canceled talk_title_formated
  rescue StandardError => ex
    Rails.logger.error ex
  end
end
