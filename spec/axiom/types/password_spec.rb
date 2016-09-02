describe Axiom::Types::Password do
  class TestConfiguration < CC::Service::Config
    attribute :password_attribute, Password
    attribute :string_attribute, String
  end

  it "password type inference" do
    expect(Axiom::Types::Password).to eq(TestConfiguration.attribute_set[:password_attribute].type)
  end

  it "string type inference" do
    expect(Axiom::Types::String).to eq(TestConfiguration.attribute_set[:string_attribute].type)
  end
end
