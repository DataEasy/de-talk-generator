require 'google/apis/drive_v3'
require 'detalk/google_drive/credential_manager'

namespace :detalk do
  desc 'Create a user to authenticate without ldap'
  task create_user: :environment do
    demo_user = 'demo'

    puts "\n"

    if User.where(username: demo_user).exists?
      puts "User #{demo_user} has already created, try login with:\nusername: #{demo_user}\npassword: #{demo_user}"
    else
      puts "Creating user #{demo_user}..."

      user = User.new username: demo_user, password: demo_user
      user.save!(validate: false)

      puts "Done. User successfully created.\n\nusername: #{demo_user}\npassword: #{demo_user}\n\n"
      puts "Do not forget to comment the line\nmanager.default_strategies(scope: :user).unshift :ldap_authenticatable\n" +
          'in config/initializers/devise.rb'
    end

    puts "\n"
  end

  desc 'Update detalk config and add google drive folder id'
  task get_google_drive_folder: :environment do
    file_config_path = Rails.root.join('config', 'detalk.yml')
    detalk_config = YAML.load_file file_config_path

    drive = Google::Apis::DriveV3::DriveService.new
    drive.authorization = DeTalk::GoogleDrive::CredentialManager.get_autorization

    google_drive_folder = detalk_config[Rails.env]['google_drive']['folder_name']

    files = drive.list_files(q: "name='#{google_drive_folder}'", spaces: 'drive')

    detalk_config[Rails.env]['google_drive']['folder_id'] = files.files.first.id

    File.open(file_config_path, 'w') { |f| YAML.dump(detalk_config, f) }
  end
end
