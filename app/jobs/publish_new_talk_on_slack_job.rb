class PublishNewTalkOnSlackJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    talk = Talk.find talk_id

    Rails.logger.debug("Publishing new talk on slack: #{talk.title_formated}")

    SlackService.new.send_new_detalk_published talk
  rescue Exception => ex
    Rails.logger.error ex
  end
end
