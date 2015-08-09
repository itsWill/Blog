class WelcomeController < ApplicationController
  skip_before_filter [:about]

  def index
    @articles
  end

  def about
    @title = "aboot"
  end
end
