class DeleteGoogleDriveFolderJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    Rails.logger.debug("Deleting folder for talk: #{talk_id}")

    google_drive_service = GoogleDriveService.new
    talk = Talk.find talk_id

    google_drive_service.delete_detalk_folder(talk.folder_id)

    talk.update(folder_id: nil)
  end
end
