require 'rails_helper'
require 'slack/web/client'

describe SlackService do
  let(:talk_plublished) { talk = build(:talk_published) }

  before do
    Rails.configuration.detalk = { 'slack' => {} }
    Rails.configuration.detalk['slack']['token'] = SecureRandom.urlsafe_base64
    Rails.configuration.detalk['slack']['channel'] = 'general'
    Rails.configuration.detalk['slack']['message'] = '%s has been published. Yay! Another talk :)'
    Rails.configuration.detalk['slack']['message_talk_canceled'] = '%s has been canceled'

    expect(Slack).to receive(:configure) {|&block| expect(block).to be_a(Proc)}

    @slack_client_mock = instance_double('Slack::Web::Client')
    allow(Slack::Web::Client).to receive(:new).with(any_args).and_return(@slack_client_mock)
  end

  it 'should publishes a new message about a published talk' do
    @cover_mock = double(File)

    expect(File).to receive(:open).with(Rails.root.join('public', 'images', talk_plublished.filename)).and_return(@cover_mock)

    allow(Rails.logger).to receive(:debug).with(any_args)

    expect(Faraday::UploadIO).to receive(:new).with(@cover_mock, 'image/png')

    expect(@slack_client_mock).to receive(:files_upload)
                                      .with(hash_including({
                                                               channels: Rails.configuration.detalk['slack']['channel'],
                                                               as_user: false,
                                                               filename: "#{talk_plublished.title_for_cover_filename}.png"
                                                           }))

    expect(@cover_mock).to receive(:close)

    expect(@slack_client_mock).to receive(:chat_postMessage).with(any_args)

    subject.send_new_detalk_published(talk_plublished)
  end

  it 'should publishes a new message about a canceled talk' do
    expect(@slack_client_mock).to receive(:chat_postMessage).with(any_args)

    subject.send_detalk_canceled(talk_plublished.title_formated)
  end
end