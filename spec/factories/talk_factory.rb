FactoryGirl.define do
  factory :talk do
    title { Faker::Name.title.truncate(30) }
    first_name { Faker::Name.first_name.truncate(10) }
    last_name { Faker::Name.last_name.truncate(10) }
    subtitle { Faker::Book.title }
    date { DateTime.now + 1.day }
    time { Faker::Time.forward(30, :afternoon) }
    target { Faker::Team.name }

    factory :talk_published do
      number { Faker::Number.between(1, 999) }
      published true
      folder_id { SecureRandom.uuid }
      filename { title_for_cover_filename }
    end
  end
end