require 'spec_helper'

describe PlayersController do
  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe 'POST generate_lineup' do

    it 'sets @lineup in the correct order for fanduel' do
      VCR.use_cassette 'players_controller/generate_lineup_fanduel1' do
        post :generate_lineup, platform: "fanduel", week: 4, type: "optimal"
        expect(assigns(:lineup).first[:position]).to eq("QB")
        expect(assigns(:lineup).second[:position]).to eq("RB")
        expect(assigns(:lineup).last[:position]).to eq("DEF")
      end
    end

    it 'sets the totals vars' do
      VCR.use_cassette 'players_controller/generate_lineup_fanduel3' do
        post :generate_lineup, platform: "fanduel", week: 4, type: "optimal"
        expect(assigns(:proj_total)).not_to be_blank
        expect(assigns(:min_total)).not_to be_blank
        expect(assigns(:max_total)).not_to be_blank
        expect(assigns(:salary_total)).not_to be_blank
      end
    end

    it 'renders the show template' do
      VCR.use_cassette 'players_controller/generate_lineup_fanduel4' do
        post :generate_lineup, platform: "fanduel", week: 4, type: "optimal"
        expect(response).to render_template(:show)
      end
    end
  end
end
