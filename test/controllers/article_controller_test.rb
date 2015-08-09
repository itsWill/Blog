require 'test_helper'

class ArticleControllerTest < ActionController::TestCase

  setup do
    @articles = ApplicationController.new.send(:load_articles)
  end

  test "should get show" do
    assert_not_nil @articles

    get :show, {title: @articles.first.title}
    assert_response :success
  end

  test "unknown article title raises an exception" do
    assert_raises do
      get :show, {title: "some invalid title"}
    end
  end
end
