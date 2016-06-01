require 'slack-ruby-client'

class SlackService
  include ServiceIntegrationHelper

  def initialize
    check_configuration!

    Slack.configure do |config|
      config.token = Rails.configuration.detalk['slack']['token']
    end
  end

  def send_detalk_canceled(talk_title_formated)
    unless Rails.configuration.detalk['slack']['channel']
      Rails.logger.warn 'The channel was not specified.'
      return
    end

    begin
      client = Slack::Web::Client.new

      message = Rails.configuration.detalk['slack']['message_talk_canceled'] % talk_title_formated

      client.chat_postMessage(channel: Rails.configuration.detalk['slack']['channel'], text: message,
                              as_user: false, username: 'slackbot')
    rescue StandardError => error
      Rails.logger.error error
    end
  end

  def send_new_detalk_published(talk)
    unless Rails.configuration.detalk['slack']['channel']
      Rails.logger.warn 'The channel was not specified.'
      return
    end

    begin
      client = Slack::Web::Client.new

      cover = File.open(Rails.root.join('public', 'images', talk.filename))

      Rails.logger.debug 'Uploading cover...'

      client.files_upload(channels: Rails.configuration.detalk['slack']['channel'], as_user: false,
                          file: Faraday::UploadIO.new(cover, 'image/png'), title: talk.title_formated,
                          filename: "#{talk.title_for_cover_filename}.png")

      cover.close

      Rails.logger.debug 'Sending message.'

      message = Rails.configuration.detalk['slack']['message'] % talk.title_formated

      client.chat_postMessage(channel: Rails.configuration.detalk['slack']['channel'], as_user: false,
                              username: 'slackbot', text: message)
    rescue StandardError => error
      Rails.logger.error error
    end
  end

  private

  def check_configuration!
    check_config_options! 'slack', %w(token channel message message_talk_canceled)
  end
end