class PlayerController < ApplicationController
  def update
    Player.refresh_data
    Projection.refresh_data("draftkings")
    render :show
  end

  def generate_lineup
    @lineup = Player.find(Projection.optimal_lineup("draftkings"))
    render :show
  end
end
