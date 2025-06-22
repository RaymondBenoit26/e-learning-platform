FactoryBot.define do
  factory :chapter do
    title { "MyString" }
    description { "MyText" }
    order { 1 }
    course { nil }
  end
end
