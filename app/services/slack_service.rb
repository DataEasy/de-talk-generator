require 'slack-ruby-client'

class SlackService
  def send_detalk_canceled(talk)
    begin
      client = Slack::Web::Client.new

      message = Rails.configuration.detalk['slack']['message_talk_canceled'] % talk.title_formated

      client.chat_postMessage(
          channel: Rails.configuration.detalk['slack']['channel'],
          text: message,
          as_user: false,
          icon_emoji: ':de_bot:'
      )
    rescue Exception => error
      Rails.logger.error error
    end
  end

  def send_new_detalk_published(talk)
    begin
      client = Slack::Web::Client.new

      cover = File.open(Rails.root.join('public', 'images', talk.filename))

      Rails.logger.debug 'Uploading cover...'

      client.files_upload(
          channels: Rails.configuration.detalk['slack']['channel'],
          as_user: false,
          file: Faraday::UploadIO.new(cover, 'image/png'),
          title: "DE Talks ##{talk.number_formated} - #{talk.title}",
          filename: "#{talk.title_for_cover_filename}.png",
          icon_emoji: ':de_bot:'
      )

      cover.close

      Rails.logger.debug 'Sending message.'

      client.chat_postMessage(
          channel: Rails.configuration.detalk['slack']['channel'],
          text: Rails.configuration.detalk['slack']['message'],
          as_user: false,
          icon_emoji: ':de_bot:'
      )
    rescue Exception => error
      Rails.logger.error error
    end
  end
end