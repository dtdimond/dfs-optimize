class PlayersController < ApplicationController
  def generate_lineup
    #Refresh data
    Player.refresh_data
    Projection.refresh_data(params[:platform])

    #Set lineup vars
    lineup_ids = Projection.optimal_lineup(params[:platform], params[:week], params[:type])
    @lineup = Projection.format_lineup(lineup_ids, params[:platform], params[:week])

    #Setup instance vars for the view
    @proj_total = 0; @min_total = 0; @max_total = 0; @salary_total = 0
    @platform = params[:platform]
    @lineup.each do |player|
      @proj_total += player[:projection].average
      @max_total += player[:projection].max
      @min_total += player[:projection].min
      @salary_total += player[:projection].salary
    end

    render :show
  end
end
