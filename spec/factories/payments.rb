FactoryBot.define do
  factory :payment do
    amount { "9.99" }
    payment_method { "MyString" }
    status { "MyString" }
    student { nil }
    payable { nil }
  end
end
