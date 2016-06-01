class HomeController < ApplicationController
  def index
    @tags_most_used = {}
    @talk = Talk.new
  end
end
