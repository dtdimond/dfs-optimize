class PlayerController < ApplicationController
  def update
    Player.refresh_data
    Projection.refresh_data
    binding.pry
    redirect_to root_path
  end
end
