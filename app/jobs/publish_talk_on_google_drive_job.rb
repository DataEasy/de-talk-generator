class PublishTalkOnGoogleDriveJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    service = GoogleDriveService.new
    talk = Talk.find talk_id

    folder_id = create_drive_folder(talk, service)

    upload_cover_to_drive_folder(talk, folder_id, service) if folder_id

  rescue Exception => ex
    Rails.logger.error ex
  end

  private

  def create_drive_folder(talk, google_drive_service)
    Rails.logger.debug("Creating folder: #{talk.title_for_cover_filename}")

    folder_id = google_drive_service.create_detalk_folder(talk.title_for_cover_filename)

    talk.update(folder_id: folder_id)

    return folder_id
  end

  def upload_cover_to_drive_folder(talk, folder_id, google_drive_service)
    Rails.logger.debug("Uploading file #{talk.filename} to #{talk.title_for_cover_filename}")

    file_destiny = Rails.root.join(CoverService::COVER_DESTINY_FOLDER, talk.filename).to_s

    content_type = MIME::Types.type_for(file_destiny).first.content_type

    google_drive_service.send_file_to_folder(talk.filename, file_destiny, content_type, folder_id)
  end
end
