class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :load_articles

  private

  def load_articles
    articles = []

    Dir.glob "#{Rails.root}/app/articles/*.md" do |file|
      meta, content = File.read(file).split("\n\n",2)

      article = OpenStruct.new YAML.load(meta)

      article.date = Time.parse article.date.to_s
      article.edited = Time.parse article.edited.to_s unless article.edited.nil?
      article.content = content

      articles << article
    end

    articles.sort_by!{|article| article.date}
    @articles = articles.reverse!
  end
end
