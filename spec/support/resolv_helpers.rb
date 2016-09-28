module ResolvHelpers
  def stub_resolv(name, address)
    allow(CC::Service::SafeWebhook).to receive(:getaddress).
      with(name).and_return(Resolv::IPv4.create(address))
  end
end

RSpec.configure do |conf|
  conf.include(ResolvHelpers)
end
