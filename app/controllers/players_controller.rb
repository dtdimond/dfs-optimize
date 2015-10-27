class PlayersController < ApplicationController
  def update
    Player.refresh_data
    Projection.refresh_data(params[:platform])
    render :show
  end

  def generate_lineup
    @lineup = Player.find(Projection.optimal_lineup(params[:platform], params[:week]))
    desired_order = ["QB","RB","WR","TE","K","DEF"]
    @lineup.sort_by! { |x| desired_order.index x.position }
    render :show
  end
end
