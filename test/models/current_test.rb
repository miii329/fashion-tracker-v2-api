require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "should store user" do
    Current.user = users(:one)
    assert_equal users(:one), Current.user
  end
end
