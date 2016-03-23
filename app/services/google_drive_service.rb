require 'google/apis/drive_v3'

class GoogleDriveService
  SERVICE_ACCOUNT_INFO = Rails.root.join('lib', 'DeTalk-ba98bca861b9.json')

  def initialize
    scope = ['https://www.googleapis.com/auth/drive']
    authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: SERVICE_ACCOUNT_INFO, scope: scope)

    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = authorization
  end

  def create_detalk_folder(folder_name)
    file_metadata = {
      name: folder_name,
      mime_type: 'application/vnd.google-apps.folder',
      parents: [get_folder_parent_id]
    }

    file = @drive.create_file(file_metadata, fields: 'id')

    file.id
  end

  def delete_detalk_folder(folder_id)
    @drive.delete_file(folder_id, fields: 'id')
  end

  private

  def get_folder_parent_id
    google_drive_folder = Rails.configuration.detalk['google_drive_folder']

    files = @drive.list_files(q: "name='#{google_drive_folder}'", spaces: 'drive')

    files.files.first.id
  end
end