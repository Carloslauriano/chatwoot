# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_status do
    sequence(:name) { |n| "Status #{n}" }
    position { 0 }

    after(:build) do |ticket_status|
      ticket_status.account ||= create(:account)
    end
  end
end
