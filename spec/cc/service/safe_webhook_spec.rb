require "spec_helper"

class CC::Service
  describe SafeWebhook do
    describe ".ensure_safe!" do
      it "does not allow internal URLs" do
        %w[ 127.0.0.1 192.168.0.1 10.0.1.18 ].each do |address|
          stub_resolv_getaddress("github.com", address)

          expect do
            SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
          end.to raise_error(SafeWebhook::InternalWebhookError)
        end
      end

      it "does not allow URLs that don't resolve via DNS" do
        allow(::Resolv).to receive(:getaddress).
          with("localhost").and_raise(::Resolv::ResolvError)

        expect do
          SafeWebhook.ensure_safe!("https://localhost/api/v1/user")
        end.to raise_error(SafeWebhook::InternalWebhookError)
      end

      it "allows internal URLs when configured to do so" do
        allow(ENV).to receive(:[]).
          with("CODECLIMATE_ALLOW_INTERNAL_WEBHOOKS").
          and_return("1")

        stub_resolv_getaddress("github.com", "10.0.1.18")

        SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
      end

      it "allows non-internal URLs" do
        stub_resolv_getaddress("github.com", "1.1.1.2")

        SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
      end
    end

    def stub_resolv_getaddress(host, ip)
      allow(::Resolv).to receive(:getaddress).
        with(host).and_return(::Resolv::IPv4.create(ip))
    end
  end
end
