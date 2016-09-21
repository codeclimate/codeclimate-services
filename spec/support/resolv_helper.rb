module ResolvHelper
  def stub_resolv(host, address)
    allow(CC::Service::SafeWebhook).to receive(:getaddress).
      with(host).and_return(address)
  end
end

RSpec.configure do |conf|
  conf.include ResolvHelper
end
