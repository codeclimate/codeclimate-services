require File.expand_path('../helper', __FILE__)

class TestService < Test::Unit::TestCase
  def test_validates_events
    assert_raises(ArgumentError) do
      CC::Service.new(:foo, {}, {})
    end
  end

  def test_default_path_to_ca_file
    s = CC::Service.new({}, {name: "test"})
    assert_equal(File.expand_path("../../config/cacert.pem", __FILE__), s.ca_file)
  end

  def test_custom_path_to_ca_file
    ENV["CODECLIMATE_CA_FILE"] = "/tmp/cacert.pem"
    s = CC::Service.new({}, {name: "test"})
    assert_equal("/tmp/cacert.pem", s.ca_file)
  ensure
    ENV.delete("CODECLIMATE_CA_FILE")
  end
end
