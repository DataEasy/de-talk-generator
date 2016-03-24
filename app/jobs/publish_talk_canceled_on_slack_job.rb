class PublishTalkCanceledOnSlackJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    talk = Talk.find talk_id

    Rails.logger.debug("Publishing talk canceled on slack: #{talk.title_formated}")

    SlackService.new.send_detalk_canceled talk
  end
end
