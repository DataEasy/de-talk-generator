require 'google/apis/drive_v3'

class GoogleDriveService
  include ServiceIntegrationHelper

  def initialize
    check_configuration!

    scope = ['https://www.googleapis.com/auth/drive']
    authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: get_service_account_json, scope: scope)

    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = authorization
  end

  def create_detalk_folder(folder_name)
    folder_parent_id = get_folder_parent_id

    return unless folder_parent_id

    file_metadata = {
      name: folder_name,
      mime_type: 'application/vnd.google-apps.folder',
      parents: [folder_parent_id]
    }

    @drive.create_file(file_metadata, fields: 'id') do |folder, error_folder|
      if error_folder
        Rails.logger.error "Fail to create folder #{folder_name}.", error_folder
        return nil
      end

      user_permission = { type: 'anyone', role: 'writer' }

      @drive.create_permission(folder.id, user_permission, fields: 'id') do |folder_permission, error_permission|
        if error_permission
          Rails.logger.error "Fail to set perssion to folder #{folder_name}-#{folder.id}.", error_permission
          return nil
        end

        return folder.id
      end
    end
  end

  def delete_detalk_folder(item_id)
    @drive.delete_file(item_id, fields: 'id') if item_id
  rescue Exception => ex
    Rails.logger.error ex
  end

  def send_file_to_folder(file_name, file_destiny, content_type, folder_id)
    file_metadata = { name: file_name, parents: [folder_id] }

    @drive.create_file(file_metadata, fields: 'id', upload_source: file_destiny,
                       content_type: content_type) do |file, error|
        if error
          Rails.logger.error "Fail to upload cover #{file_destiny} to #{folder_id}.", error
          return nil
        end

        return file.id
    end
  end

  private

  def get_folder_parent_id
    shared_folder_id = Rails.configuration.detalk['google_drive']['shared_folder_id']
    return shared_folder_id if shared_folder_id

    shared_folder_id = get_folder_id_by_name(Rails.configuration.detalk['google_drive']['shared_folder'])

    return unless shared_folder_id

    Rails.configuration.detalk['google_drive']['shared_folder_id'] = shared_folder_id

    shared_folder_id
  end

  def get_folder_id_by_name(folder_name)
    files = @drive.list_files(q: "name='#{folder_name}'", spaces: 'drive')

    if files.files.empty?
      Rails.logger.warn "the google drive folder '#{folder_name}' was not found."
      return nil
    end

    files.files.first.id
  end

  def get_service_account_json
    File.new Rails.configuration.detalk['google_drive']['service_account_json'], File::RDONLY
  end

  def check_configuration!
    check_config_options! 'google_drive', %w(shared_folder service_account_json)
  end
end