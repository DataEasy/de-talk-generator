class CreateGoogleDriveFolderJob < ActiveJob::Base
  queue_as :default

  def perform(talk_id)
    talk = Talk.find talk_id

    Rails.logger.debug("Creating folder: #{talk.title_for_cover_filename}")

    folder_id = GoogleDriveService.new.create_detalk_folder(talk.title_for_cover_filename)

    talk.update(folder_id: folder_id)
  end
end
