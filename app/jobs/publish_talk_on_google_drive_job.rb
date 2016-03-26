class PublishTalkOnGoogleDriveJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    talk = Talk.find talk_id

    Rails.logger.debug("Creating folder: #{talk.title_for_cover_filename}")

    service = GoogleDriveService.new
    folder_id = service.create_detalk_folder(talk.title_for_cover_filename)

    talk.update(folder_id: folder_id)

    if folder_id
      Rails.logger.debug("Uploading file #{talk.filename} to #{talk.title_for_cover_filename}")

      file_destiny = Rails.root.join(CoverService::COVER_DESTINY_FOLDER, talk.filename).to_s

      content_type = MIME::Types.type_for(file_destiny).first.content_type

      service.send_file_to_folder(talk.filename, file_destiny, content_type, folder_id)
    end
  end
end
