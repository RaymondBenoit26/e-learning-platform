FactoryBot.define do
  factory :license do
    name { "MyString" }
    description { "MyText" }
    price { "9.99" }
    max_seats { 1 }
    valid_until { "2025-06-18" }
    term { nil }
  end
end
