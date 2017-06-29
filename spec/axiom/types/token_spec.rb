describe Axiom::Types::Token do
  class TestConfiguration < CC::Service::Config
    attribute :token_attribute, Token
    attribute :str_attribute, String
  end

  it "token type inference" do
    expect(Axiom::Types::Token).to eq(TestConfiguration.attribute_set[:token_attribute].type)
  end

  it "string type inference" do
    expect(Axiom::Types::String).to eq(TestConfiguration.attribute_set[:str_attribute].type)
  end
end
