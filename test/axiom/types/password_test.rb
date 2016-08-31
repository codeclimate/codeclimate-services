require File.expand_path("../../../helper", __FILE__)

class Axiom::Types::PasswordTest < CC::Service::TestCase
  class TestConfiguration < CC::Service::Config
    attribute :password_attribute, Password
    attribute :string_attribute, String
  end

  def test_password_type_inference
    assert_equal(
      Axiom::Types::Password,
      TestConfiguration.attribute_set[:password_attribute].type,
    )
  end

  def test_string_type_inference
    assert_equal(
      Axiom::Types::String,
      TestConfiguration.attribute_set[:string_attribute].type,
    )
  end
end
