class ArticleController < ApplicationController
  def show
    @article = load_article_by_title( params[:title] ) or raise ActionController::RoutingError.new("Not Found")
  end

  private

  def load_article_by_title(title)
    @articles.each do |article|
      @article = article if article.title == title
    end
    @article
  end
end
