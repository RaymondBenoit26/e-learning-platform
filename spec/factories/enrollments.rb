FactoryBot.define do
  factory :enrollment do
    student { nil }
    course { nil }
    payable { nil }
    status { "MyString" }
  end
end
