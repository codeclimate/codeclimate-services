require "spec_helper"

class CC::Service
  describe SafeWebhook do
    describe ".ensure_safe!" do
      it "does not allow internal URLs" do
        %w[ 127.0.0.1 192.168.0.1 10.0.1.18 ].each do |address|
          stub_resolv("github.com", address)

          expect do
            SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
          end.to raise_error(SafeWebhook::InternalWebhookError)
        end
      end

      it "allows internal URLs when configured to do so" do
        allow(ENV).to receive(:[]).
          with("CODECLIMATE_ALLOW_INTERNAL_WEBHOOKS").
          and_return("1")

        stub_resolv("github.com", "10.0.1.18")

        SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
      end

      it "allows non-internal URLs" do
        stub_resolv("github.com", "1.1.1.2")

        SafeWebhook.ensure_safe!("https://github.com/api/v1/user")
      end

      it "ensures future dns queries get the same answer" do
        stub_resolv("github.com", "1.1.1.3")

        SafeWebhook.ensure_safe!("https://github.com/api/v1/user")

        expect(Resolv.getaddress("github.com").to_s).to eq "1.1.1.3"
      end
    end
  end
end
