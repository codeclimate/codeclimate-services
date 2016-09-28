describe CC::Service, type: :service do
  it "validates events" do
    expect { CC::Service.new(:foo, {}, {}, {}) }.to raise_error(ArgumentError)
  end

  it "default path to ca file" do
    s = CC::Service.new({}, name: "test")
    expect(File.expand_path("../../../config/cacert.pem", __FILE__)).to eq(s.ca_file)
    expect(File.exist?(s.ca_file)).to eq(true)
  end

  it "custom path to ca file" do
    begin
      ENV["CODECLIMATE_CA_FILE"] = "/tmp/cacert.pem"
      s = CC::Service.new({}, name: "test")
      expect("/tmp/cacert.pem").to eq(s.ca_file)
    ensure
      ENV.delete("CODECLIMATE_CA_FILE")
    end
  end

  it "nothing has a handler" do
    service = CC::Service.new({}, name: "test")

    result = service.receive

    expect(result[:ok]).to eq(false)
    expect(result[:ignored]).to eq(true)
    expect(result[:message]).to eq("No service handler found")
  end

  it "post success" do
    stub_http("/my/test/url", [200, {}, '{"ok": true, "thing": "123"}'])

    response = service_post("http://example.com/my/test/url", { token: "1234" }.to_json, {}) do |inner_response|
      body = JSON.parse(inner_response.body)
      { thing: body["thing"] }
    end

    expect(response[:ok]).to eq(true)
    expect(response[:params]).to eq('{"token":"1234"}')
    expect(response[:endpoint_url]).to eq("http://example.com/my/test/url")
    expect(response[:status]).to eq(200)
  end

  it "post redirect success" do
    stub_http("/my/test/url", [307, { "Location" => "http://example.com/my/redirect/url" }, '{"ok": false, "redirect": true}'])
    stub_http("/my/redirect/url", [200, {}, '{"ok": true, "thing": "123"}'])

    response = service_post_with_redirects("http://example.com/my/test/url", { token: "1234" }.to_json, {}) do |inner_response|
      body = JSON.parse(inner_response.body)
      { thing: body["thing"] }
    end

    expect(response[:ok]).to eq(true)
    expect(response[:params]).to eq('{"token":"1234"}')
    expect(response[:endpoint_url]).to eq("http://example.com/my/test/url")
    expect(response[:status]).to eq(200)
  end

  it "post http failure" do
    stub_http("/my/wrong/url", [404, {}, ""])

    expect { service_post("http://example.com/my/wrong/url", { token: "1234" }.to_json, {}) }.to raise_error(CC::Service::HTTPError)
  end

  it "post some other failure" do
    stub_http("/my/wrong/url") { raise ArgumentError, "lol" }

    expect { service_post("http://example.com/my/wrong/url", { token: "1234" }.to_json, {}) }.to raise_error(ArgumentError)
  end

  it "services" do
    services = CC::Service.services

    expect(services.include?(CC::PullRequests)).not_to eq(true)
  end
end
