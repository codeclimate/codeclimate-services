require File.expand_path("../helper", __FILE__)

class TestService < CC::Service::TestCase
  def test_validates_events
    assert_raises(ArgumentError) do
      CC::Service.new(:foo, {}, {}, {})
    end
  end

  def test_default_path_to_ca_file
    s = CC::Service.new({}, {name: "test"}, FalsyRepoConfig.new)
    assert_equal(File.expand_path("../../config/cacert.pem", __FILE__), s.ca_file)
    assert File.exist?(s.ca_file)
  end

  def test_custom_path_to_ca_file
    ENV["CODECLIMATE_CA_FILE"] = "/tmp/cacert.pem"
    s = CC::Service.new({}, {name: "test"}, FalsyRepoConfig.new)
    assert_equal("/tmp/cacert.pem", s.ca_file)
  ensure
    ENV.delete("CODECLIMATE_CA_FILE")
  end

  def test_nothing_has_a_handler
    service = CC::Service.new({}, {name: "test"}, FalsyRepoConfig.new)

    result = service.receive

    assert_equal false, result[:ok]
    assert_equal "No service handler found", result[:message]
  end

  def test_post_success
    stub_http("/my/test/url", [200, {}, '{"ok": true, "thing": "123"}'])

    response = service_post("/my/test/url", {token: "1234"}.to_json, {}) do |response|
      body = JSON.parse(response.body)
      { thing: body["thing"] }
    end

    assert_true response[:ok]
    assert_equal '{"token":"1234"}', response[:params]
    assert_equal "/my/test/url", response[:endpoint_url]
    assert_equal 200, response[:status]
  end

  def test_post_http_failure
    stub_http("/my/wrong/url", [404, {}, ""])

    assert_raises(CC::Service::HTTPError) do
      service_post("/my/wrong/url", {token: "1234"}.to_json, {})
    end
  end

  def test_post_some_other_failure
    stub_http("/my/wrong/url"){ raise ArgumentError.new("lol") }

    assert_raises(ArgumentError) do
      service_post("/my/wrong/url", {token: "1234"}.to_json, {})
    end
  end
end
