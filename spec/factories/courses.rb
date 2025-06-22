FactoryBot.define do
  factory :course do
    name { "MyString" }
    description { "MyText" }
    school { nil }
    term { nil }
  end
end
