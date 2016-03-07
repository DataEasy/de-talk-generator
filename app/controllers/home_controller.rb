class HomeController < ApplicationController
  def index
    @tags_most_used = ActsAsTaggableOn::Tag.most_used(10)
    @talk = Talk.new
  end
end
