FactoryGirl.define do
  factory :user do
    username { Faker::Internet.user_name }
    password 'f4k3p455w0rd'
    password_confirmation 'f4k3p455w0rd'

    factory :another_user, class: User do
      username { Faker::Internet.user_name }
    end
  end
end
