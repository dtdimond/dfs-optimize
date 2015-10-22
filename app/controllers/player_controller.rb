class PlayerController < ApplicationController
  def update
    WebMock.disable!
    Player.refresh_data
    Salary.refresh_data
    Projection.refresh_data
    binding.pry
    WebMock.enable!
    redirect_to root_path
  end
end
