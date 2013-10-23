require 'test_helper'

class RailsWrappersTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, RailsWrappers
  end
end
