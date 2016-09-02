require File.expand_path("../helper", __FILE__)

class TestService < CC::Service::TestCase
  it "validates events" do
    assert_raises(ArgumentError) do
      CC::Service.new(:foo, {}, {}, {})
    end
  end

  it "default path to ca file" do
    s = CC::Service.new({}, name: "test")
    assert_equal(File.expand_path("../../config/cacert.pem", __FILE__), s.ca_file)
    File.exist?(s.ca_file).should.not == nil
  end

  it "custom path to ca file" do
    ENV["CODECLIMATE_CA_FILE"] = "/tmp/cacert.pem"
    s = CC::Service.new({}, name: "test")
    assert_equal("/tmp/cacert.pem", s.ca_file)
  ensure
    ENV.delete("CODECLIMATE_CA_FILE")
  end

  it "nothing has a handler" do
    service = CC::Service.new({}, name: "test")

    result = service.receive

    result[:ok].should == false
    true, result[:ignored].should == true
    result[:message].should == "No service handler found"
  end

  it "post success" do
    stub_http("/my/test/url", [200, {}, '{"ok": true, "thing": "123"}'])

    response = service_post("/my/test/url", { token: "1234" }.to_json, {}) do |inner_response|
      body = JSON.parse(inner_response.body)
      { thing: body["thing"] }
    end

    response[:ok].should == true
    response[:params].should == '{"token":"1234"}'
    response[:endpoint_url].should == "/my/test/url"
    response[:status].should == 200
  end

  it "post redirect success" do
    stub_http("/my/test/url", [307, { "Location" => "/my/redirect/url" }, '{"ok": false, "redirect": true}'])
    stub_http("/my/redirect/url", [200, {}, '{"ok": true, "thing": "123"}'])

    response = service_post_with_redirects("/my/test/url", { token: "1234" }.to_json, {}) do |inner_response|
      body = JSON.parse(inner_response.body)
      { thing: body["thing"] }
    end

    response[:ok].should == true
    response[:params].should == '{"token":"1234"}'
    response[:endpoint_url].should == "/my/test/url"
    response[:status].should == 200
  end

  it "post http failure" do
    stub_http("/my/wrong/url", [404, {}, ""])

    assert_raises(CC::Service::HTTPError) do
      service_post("/my/wrong/url", { token: "1234" }.to_json, {})
    end
  end

  it "post some other failure" do
    stub_http("/my/wrong/url") { raise ArgumentError, "lol" }

    assert_raises(ArgumentError) do
      service_post("/my/wrong/url", { token: "1234" }.to_json, {})
    end
  end

  it "services" do
    services = CC::Service.services

    services.include?(CC::PullRequests).should.not == true
  end
end
