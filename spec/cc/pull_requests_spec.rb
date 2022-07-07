require "spec_helper"

describe CC::PullRequests do
  shared_examples "receive method" do
    before do
      allow(instance).to receive(:report_status?).and_return(true)
      expect(instance).to receive(:setup_http)
    end

    context "when the status is valid" do
      let(:instance) { CC::PullRequests.new({}, name: "test", state: payload_status) }
      let(:response) do
        {
          ok: true,
          state: 201,
          message: "Success",
        }
      end

      it "calls the corresponding method" do
        expect(instance).to receive(expected_method_name) do
          instance.instance_variable_set(:@response, response)
        end
        result = instance.send(method_to_call)

        expect(result).to eq(response)
      end

      context "when report_status? is false" do
        before { expect(instance).to receive(:report_status?).and_return(false) }

        it "returns unknown status message" do
          expect(instance).not_to receive(expected_method_name)
          result = instance.send(method_to_call)

          expect(result).to eq({ ok: false, message: "Unknown state" })
        end
      end
    end

    context "when the status is not valid" do
      let(:instance) { CC::PullRequests.new({}, name: "test", status: "invalid_status") }

      it "returns unknown status message" do
        expect(instance).not_to receive(expected_method_name)
        result = instance.send(method_to_call)

        expect(result).to eq({ ok: false, message: "Unknown state" })
      end
    end
  end

  describe "#receive_test" do
    let(:instance) { CC::PullRequests.new({}, name: "test") }

    before do
      expect(instance).to receive(:base_status_url) do |param|
        "some_url" + param
      end
      expect(instance).to receive(:setup_http)
    end

    it "makes a raw http test post" do
      expect_any_instance_of(CC::Service::HTTP).to receive(:raw_post).with(
        "some_url" + ("0" * 40),
        { state: "success" }.to_json
      )

      instance.receive_test
    end

    context "when raising an HTTPError" do
      context "when message is equal to test_status_code" do
        it "returns an ok message" do
          expect(instance).to receive(:test_status_code) { 777 }
          expect(instance).to receive(:raw_post).
            and_raise(CC::Service::HTTPError.new("error", status: 777))

          result = instance.receive_test
          expect(result).to include(
            ok: true,
            status: 777,
            message: "Access token is valid"
          )
        end
      end

      context "when message is different than test_status_code" do
        it "raises the error" do
          expect(instance).to receive(:test_status_code) { 777 }
          expect(instance).to receive(:raw_post).
            and_raise(CC::Service::HTTPError.new("error", status: 000))

          expect { instance.receive_test }.to raise_error
        end
      end
    end
  end

  describe "#receive_pull_request" do
    let(:payload_status) { "skipped" }
    let(:expected_method_name) { :update_status_skipped }
    let(:method_to_call) { :receive_pull_request }

    it_behaves_like "receive method"
  end

  describe "#receive_pull_request_coverage" do
    let(:payload_status) { "success" }
    let(:expected_method_name) { :update_coverage_status_success }
    let(:method_to_call) { :receive_pull_request_coverage }

    it_behaves_like "receive method"
  end

  describe "#receive_pull_request_diff_coverage" do
    let(:payload_status) { "skipped" }
    let(:expected_method_name) { :update_diff_coverage_status_skipped }
    let(:method_to_call) { :receive_pull_request_diff_coverage }

    it_behaves_like "receive method"
  end

  describe "#receive_pull_request_total_coverage" do
    let(:payload_status) { "skipped" }
    let(:expected_method_name) { :update_total_coverage_status_skipped }
    let(:method_to_call) { :receive_pull_request_total_coverage }

    it_behaves_like "receive method"
  end
end
