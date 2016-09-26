require "spec_helper"

class CC::Service
  describe SafeWebhook do
    describe ".getaddress" do
      it "resolves the dns name to a string" do
        address = SafeWebhook.getaddress("codeclimate.com")

        expect(address).to be_present
        expect(address).to respond_to(:start_with?)
      end
    end

    describe "#validate!" do
      context "valid webhook URLs" do
        it "rewrites the request to be safe" do
          stub_resolv("example.com", "2.2.2.2")

          request = double(headers: double)
          expect(request).to receive(:url).with("https://2.2.2.2:3000/foo")
          expect(request.headers).to receive(:update).with(Host: "example.com")

          safe_webhook = SafeWebhook.new("https://example.com:3000/foo")
          safe_webhook.validate!(request)
        end
      end

      context "invalid Webhook URLs" do
        it "raises for invalid URL" do
          allow(URI).to receive(:parse).and_raise(URI::InvalidURIError)

          expect { validate("http://example.com") }.to raise_error(SafeWebhook::InvalidWebhookURL)
        end

        it "raises for un-resolvable URL" do
          allow(SafeWebhook).to receive(:getaddress).and_raise(Resolv::ResolvError)

          expect { validate("http://example.com") }.to raise_error(SafeWebhook::InvalidWebhookURL)
        end

        it "raises for localhost URLs" do
          stub_resolv("example.com", "127.0.0.1")

          expect { validate("http://example.com") }.to raise_error(SafeWebhook::InvalidWebhookURL)
        end

        it "raises for internal URLs" do
          stub_resolv("example.com", "10.0.0.1")

          expect { validate("http://example.com") }.to raise_error(SafeWebhook::InvalidWebhookURL)
        end

        def validate(url)
          request = double
          safe_webhook = SafeWebhook.new(url)
          safe_webhook.validate!(request)
        end
      end
    end
  end
end
