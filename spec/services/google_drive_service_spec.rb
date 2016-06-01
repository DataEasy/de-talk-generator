require 'rails_helper'
require 'google/apis/drive_v3'

describe GoogleDriveService do
  let(:default_parent_folder){ Rails.configuration.detalk['google_drive']['shared_folder'] }
  let(:default_parent_folder_id){ SecureRandom.urlsafe_base64 }

  before do
    Rails.configuration.detalk = { 'google_drive' => {} }
    Rails.configuration.detalk['google_drive']['service_account_json'] = "#{::Rails.root}/spec/fixtures/service_account_credentials.json"
    Rails.configuration.detalk['google_drive']['shared_folder'] = 'GD_Test'

    @drive_service_mock = instance_double('Google::Apis::DriveV3::DriveService')
    credential_mock = object_double(Google::Auth::ServiceAccountCredentials)

    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).with(any_args).and_return(credential_mock)
    allow(Google::Apis::DriveV3::DriveService).to receive(:new).with(any_args).and_return(@drive_service_mock)

    expect(@drive_service_mock).to receive(:authorization=).with(any_args)

    @service = GoogleDriveService.new
  end

  describe '#create_detalk_folder' do
    before do
      @talk = Talk.new(number: 1, title: 'New Talk About Rails')
      folder_mock = object_double('default_folder', id: default_parent_folder_id)
      folder_list_mock = object_double('folder_list', files: [folder_mock])

      expect(@drive_service_mock).to receive(:list_files)
                                         .with(q: "name='#{default_parent_folder}'", spaces: 'drive')
                                         .and_return(folder_list_mock)
    end

    context 'when a error occurs with drive service calling create_file' do
      it 'should not create a folder' do
        error_folder = 'Something has gone wrong on calling the create_file'
        folder = nil

        param = { name: @talk.title_for_cover_filename, parents: [default_parent_folder_id] }
        expect(@drive_service_mock).to receive(:create_file)
                                           .with(hash_including(param), fields: 'id')
                                           .and_yield(folder, error_folder)

        expect(Rails.logger).to receive(:error).with(/#{@talk.title_for_cover_filename}/).and_call_original

        id = @service.create_detalk_folder(@talk.title_for_cover_filename)

        expect(id).to be_nil
      end
    end

    context 'when an error occurs with drive service calling create_permission' do
      it 'should create a folder but do not return the folder id' do
        folder_id = SecureRandom.urlsafe_base64
        folder = double('drive_folder', id: folder_id)

        param = { name: @talk.title_for_cover_filename, parents: [default_parent_folder_id] }
        expect(@drive_service_mock).to receive(:create_file)
                                           .with(hash_including(param), fields: 'id').and_yield(folder, nil)

        param_permission = { type: 'anyone', role: 'writer' }
        error_permission = 'Some permission error has happened'

        expect(@drive_service_mock).to receive(:create_permission)
                                           .with(folder.id, hash_including(param_permission), fields: 'id')
                                           .and_yield(nil, error_permission)

        expect(Rails.logger).to receive(:error).with(/#{@talk.title_for_cover_filename}-#{folder_id}/).and_call_original

        id = @service.create_detalk_folder(@talk.title_for_cover_filename)

        expect(id).to be_nil
      end
    end

    context 'when everything is ok' do
      it 'should create a folder and return folder id' do
        folder_id = SecureRandom.urlsafe_base64
        folder = double('drive_folder', id: folder_id)

        param = { name: @talk.title_for_cover_filename, parents: [default_parent_folder_id] }
        expect(@drive_service_mock).to receive(:create_file)
                                           .with(hash_including(param), fields: 'id').and_yield(folder, nil)

        param_permission = { type: 'anyone', role: 'writer' }
        expect(@drive_service_mock).to receive(:create_permission)
                                           .with(folder.id, hash_including(param_permission), fields: 'id')
                                           .and_yield(nil, nil)

        id = @service.create_detalk_folder(@talk.title_for_cover_filename)

        expect(id).to_not be_nil
        expect(id).to eq folder_id
      end
    end
  end

  describe '#send_file_to_folder' do
    let(:filename){ 'cover_test.png' }
    let(:file_content_type){ 'image/png' }
    let(:file_source){ '/tmp/cover' }
    let(:file_metadata){ { name: filename, parents: [default_parent_folder_id] } }

    it 'should send file and return the file id' do
      expect(@service).to_not be_nil
      file_mock = double('file_mock_response', id: SecureRandom.urlsafe_base64)

      expect(@drive_service_mock).to receive(:create_file)
                                         .with(hash_including(file_metadata), fields: 'id',
                                               upload_source: file_source, content_type: file_content_type)
                                         .and_yield(file_mock, nil)

      file_id = @service.send_file_to_folder(filename, file_source, file_content_type, default_parent_folder_id)
      expect(file_id).to_not be_nil
      expect(file_id).to eq file_mock.id
    end

    context 'when an error occurs with drive service calling create_file' do
      it 'should not send the file' do
        file_error = 'Some random error'

        expect(@drive_service_mock).to receive(:create_file)
                                           .with(hash_including(file_metadata), fields: 'id',
                                                 upload_source: file_source, content_type: file_content_type)
                                           .and_yield(nil, file_error)

        expect(Rails.logger).to receive(:error).with(/#{filename} to #{default_parent_folder_id}/).and_call_original

        file_id = @service.send_file_to_folder(filename, file_source, file_content_type, default_parent_folder_id)

        expect(file_id).to be_nil
      end
    end
  end
end