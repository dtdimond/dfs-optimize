class PlayerController < ApplicationController
  def update
    Player.refresh_data
    Projection.refresh_data
    redirect_to root_path
  end
end
