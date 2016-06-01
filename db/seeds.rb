# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

demo_user = 'demo'
if User.where(username: demo_user).exists?
  puts "User #{demo_user} has already created, try login with:\nusername: #{demo_user}\npassword: #{demo_user}"
else
  user = User.new username: demo_user, password: demo_user
  user.save!(validate: false)
end