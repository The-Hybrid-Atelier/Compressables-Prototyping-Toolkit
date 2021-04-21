class IotController < ApplicationController
  def server
  end
  def air
  end
  def compressables
  end
  def video
  end
  def meter
    render layout: "paper"
  end
end
