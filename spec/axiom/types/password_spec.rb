require File.expand_path("../../../helper", __FILE__)

class Axiom::Types::PasswordTest < CC::Service::TestCase
  class TestConfiguration < CC::Service::Config
    attribute :password_attribute, Password
    attribute :string_attribute, String
  end

  it "password type inference" do
    assert_equal(
      Axiom::Types::Password,
      TestConfiguration.attribute_set[:password_attribute].type,
    )
  end

  it "string type inference" do
    assert_equal(
      Axiom::Types::String,
      TestConfiguration.attribute_set[:string_attribute].type,
    )
  end
end
