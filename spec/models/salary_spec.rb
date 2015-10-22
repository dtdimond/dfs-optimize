require 'spec_helper'

describe Salary do
  it { should belong_to(:player) }

  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe ".refresh_data" do
    it 'gets all new salary data if an existing salary record is too old' do
      Fabricate(:salary, platform: "fanduel", updated_at: not_too_new)
      Fabricate(:salary, platform: "fanduel", updated_at: too_new)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.first.value).to eq(8000)
      expect(Salary.first.week).to eq(4)
      expect(Salary.first.platform).to eq("fanduel")
      expect(Salary.first.player_id).to eq(35)
    end

    it 'gets all new salary data if there are no records' do
      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.first.value).to eq(8000)
    end

    it 'gets no new salary data if all existing salary records are too recent' do
      Fabricate(:salary, platform: "fanduel", updated_at: too_new)
      Fabricate(:salary, platform: "fanduel", updated_at: too_new)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.third).to be_nil
    end

    it 'gets new salary data if a record is old enough, but for wrong platform' do
      Fabricate(:salary, platform: "draftkings", updated_at: not_too_new)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data
      end

      expect(Salary.second.value).to eq(8000)
    end

    it 'only deletes records for the given platform on refresh' do
      Fabricate(:salary, platform: "draftkings", updated_at: too_new)
      salary_fd = Fabricate(:salary, platform: "fanduel", updated_at: not_too_new)

      VCR.use_cassette 'salary/refresh_data' do
        Salary.refresh_data("fanduel")
      end

      expect(Salary.first.platform).to eq("draftkings")
      expect(Salary.second.updated_at).not_to be_near_to_time(salary_fd.updated_at, 30.seconds)
    end
  end

  describe ".populate_data" do
    it 'populates the salary database' do
      VCR.use_cassette 'salary/populate_data' do
        Salary.populate_data("fanduel")
      end

      expect(Salary.first.value).to eq(8000)
      expect((Salary.first.updated_at)).to be_near_to_time(Time.now, 30.seconds)
    end
  end

  describe "#refresh?" do
    it 'returns false if updated_at is less than 60mins old' do
      salary = Fabricate(:salary, updated_at: too_new)
      expect(salary.refresh?).to be false
    end

    it 'returns true if updated_at is greater than 60mins old' do
      salary = Fabricate(:salary, updated_at: not_too_new)
      expect(salary.refresh?).to be true
    end
  end
end
