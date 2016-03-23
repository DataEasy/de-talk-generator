class CreateGoogleDriveFolderJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    Rails.logger.debug("Creating folder for talk: #{talk_id}")

    google_drive_service = GoogleDriveService.new
    talk = Talk.find talk_id

    folder_id = google_drive_service.create_detalk_folder(talk.title_for_cover_filename)

    talk.update(folder_id: folder_id)
  end
end
