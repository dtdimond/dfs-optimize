require 'spec_helper'

describe PlayersController do
  let!(:old_api_key) { FFNerd.api_key }
  before { FFNerd.api_key = "test" }
  after { FFNerd.api_key = old_api_key }

  describe 'POST generate_lineup' do
    it 'sets @lineup' do
      VCR.use_cassette 'players_controller/generate_lineup_fanduel1' do
        post :generate_lineup, platform: "fanduel", week: 4, type: "optimal"
        expect(assigns(:lineup)).to_not be_nil
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

    it 'renders the index template' do
      VCR.use_cassette 'players_controller/generate_lineup_fanduel4' do
        post :generate_lineup, platform: "fanduel", week: 4, type: "optimal"
        expect(response).to render_template(:index)
      end
    end
  end

  describe 'GET index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end
end
