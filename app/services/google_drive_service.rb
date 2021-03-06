require 'google/apis/drive_v3'

class GoogleDriveService
  include ServiceIntegrationHelper

  def initialize
    check_configuration!

    scope = ['https://www.googleapis.com/auth/drive']
    authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: service_account_json, scope: scope)

    @drive = Google::Apis::DriveV3::DriveService.new
    @drive.authorization = authorization
  end

  def create_detalk_folder(folder_name)
    return unless folder_parent_id

    file_metadata = { name: folder_name, mime_type: 'application/vnd.google-apps.folder', parents: [folder_parent_id] }

    @drive.create_file(file_metadata, fields: 'id') do |folder, error_folder|
      if error_folder
        Rails.logger.error "Fail to create folder #{folder_name}.\n#{error_folder}"
        return nil
      end

      user_permission = { type: 'anyone', role: 'writer' }

      @drive.create_permission(folder.id, user_permission, fields: 'id') do |_folder_permission, error_permission|
        if error_permission
          Rails.logger.error "Fail to set perssion to folder #{folder_name}-#{folder.id}.\n#{error_permission}"
          return nil
        end

        return folder.id
      end
    end
  end

  def delete_detalk_folder(item_id)
    @drive.delete_file(item_id, fields: 'id') if item_id
  rescue StandardError => ex
    Rails.logger.error ex
  end

  def send_file_to_folder(file_name, file_source_path, content_type, folder_id)
    file_metadata = { name: file_name, parents: [folder_id] }

    @drive.create_file(file_metadata, fields: 'id', upload_source: file_source_path, content_type: content_type) do |file, error|
        if error
          Rails.logger.error "Fail to upload cover #{file_name} to #{folder_id}.\n#{error}"
          return nil
        end

        return file.id
    end
  end

  private

  def folder_parent_id
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

  def service_account_json
    File.new Rails.configuration.detalk['google_drive']['service_account_json'], File::RDONLY
  end

  def check_configuration!
    check_config_options! 'google_drive', %w(shared_folder service_account_json)
  end
end