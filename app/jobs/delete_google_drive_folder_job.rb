class DeleteGoogleDriveFolderJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    talk = Talk.find talk_id

    Rails.logger.debug("Deleting folder: #{talk.title_for_cover_filename}")

    GoogleDriveService.new.delete_detalk_folder(talk.folder_id)

    talk.update(folder_id: nil)
  rescue StandardError => ex
    Rails.logger.error ex
  end
end
