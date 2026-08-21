# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketStatus do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:ticket_status_teams).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:ticket_status_teams) }
    it { is_expected.to have_many(:tickets).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'team_ids=' do
    it 'links the status to the given teams' do
      account = create(:account)
      team_a = create(:team, account: account)
      team_b = create(:team, account: account)
      ticket_status = create(:ticket_status, account: account)

      ticket_status.team_ids = [team_a.id, team_b.id]

      expect(ticket_status.reload.teams).to contain_exactly(team_a, team_b)
    end
  end
end
