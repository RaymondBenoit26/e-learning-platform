FactoryBot.define do
  factory :instructor do
    first_name { "MyString" }
    last_name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    bio { "MyText" }
    school { nil }
  end
end
