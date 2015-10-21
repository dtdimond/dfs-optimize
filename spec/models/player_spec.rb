require 'spec_helper'

describe Player do
  it { should have_many(:projections) }
  it { should have_many(:salaries) }
  it { should have_many(:caches) }

  describe ".get_data" do
    it 'gets the player data' do
      Player.get_data
      flacco = Player.all.first
      expect(flacco).not_to be_nil
      #expect(flacco.name).to eq("Joe Flacco")
    end

    it 'updates the player data updated timestamp'
  end
end
