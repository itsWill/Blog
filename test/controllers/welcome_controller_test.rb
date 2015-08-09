require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get about" do
    get :about
    assert_response :success
  end

  test "title is correctly displayed" do
    get :about
    assert_select "title", "aboot | GRPM | Blog"
  end
end
