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
end
