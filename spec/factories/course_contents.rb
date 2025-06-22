FactoryBot.define do
  factory :course_content do
    title { "MyString" }
    description { "MyText" }
    content_type { "MyString" }
    course { nil }
    chapter { nil }
  end
end
