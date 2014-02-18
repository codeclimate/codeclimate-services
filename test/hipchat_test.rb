require File.expand_path('../helper', __FILE__)

class TestHipChat < CC::Service::TestCase
  def test_test_hook
    assert_hipchat_receives(
      :test,
      "green",
      { repo_name: "Rails" },
      "[Rails] This is a test of the HipChat service hook"
    )
  end

  def test_coverage_improved
    assert_hipchat_receives(:coverage, "green", {
      repo_name: "Rails",
      covered_percent: 90.2,
      previous_covered_percent: 80.0,
      details_url: "https://codeclimate.com/repos/1/feed",
      compare_url: "https://codeclimate.com/repos/1/compare"
    }, [
      "[Rails]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has improved to 90.2% (+10.2%)",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_coverage_declined_without_compare_url
    assert_hipchat_receives(:coverage, "red", {
      repo_name: "Rails",
      covered_percent: 80.0,
      previous_covered_percent: 86.2,
      details_url: "https://codeclimate.com/repos/1/feed",
    }, [
      "[Rails]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">Test coverage</a>",
      "has declined to 80.0% (-6.2%)"
    ].join(" "))
  end

  def test_quality_improved
    assert_hipchat_receives(:quality, "green", {
      repo_name: "Rails",
      constant_name: "User",
      rating: "A",
      previous_rating: "B",
      remediation_cost: 50,
      previous_remediation_cost: 25,
      details_url: "https://codeclimate.com/repos/1/feed",
      compare_url: "https://codeclimate.com/repos/1/compare"
    }, [
      "[Rails]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has improved from a B to an A",
      "(<a href=\"https://codeclimate.com/repos/1/compare\">Compare</a>)"
    ].join(" "))
  end

  def test_quality_declined_without_compare_url
    assert_hipchat_receives(:quality, "red", {
      repo_name: "Rails",
      constant_name: "User",
      rating: "D",
      previous_rating: "C",
      remediation_cost: 25,
      previous_remediation_cost: 50,
      details_url: "https://codeclimate.com/repos/1/feed",
    }, [
      "[Rails]",
      "<a href=\"https://codeclimate.com/repos/1/feed\">User</a>",
      "has declined from a C to a D",
    ].join(" "))
  end

  def test_single_vulnerability
    assert_hipchat_receives(:vulnerability, "red", {
      repo_name: "Rails",
      vulnerabilities: [{ "warning_type" => "critical" }],
      details_url: "https://codeclimate.com/repos/1/vulnerabilities"
    }, [
      "[Rails]",
      "New <a href=\"https://codeclimate.com/repos/1/vulnerabilities\">critical</a>",
      "issue found.",
    ].join(" "))
  end

  def test_single_vulnerability_with_location
    assert_hipchat_receives(:vulnerability, "red", {
      repo_name: "Rails",
      vulnerabilities: [{
        "warning_type" => "critical",
        "location" => "app/user.rb line 120"
      }],
      details_url: "https://codeclimate.com/repos/1/vulnerabilities"
    }, [
      "[Rails]",
      "New <a href=\"https://codeclimate.com/repos/1/vulnerabilities\">critical</a>",
      "issue found in app/user.rb line 120.",
    ].join(" "))
  end

  def test_multiple_vulnerabilities
    assert_hipchat_receives(:vulnerability, "red", {
      repo_name: "Rails",
      warning_type: "critical",
      vulnerabilities: [{
        "warning_type" => "unused",
        "location" => "unused"
      }, {
        "warning_type" => "unused",
        "location" => "unused"
      }],
      details_url: "https://codeclimate.com/repos/1/vulnerabilities"
    }, [
      "[Rails]",
      "2 new <a href=\"https://codeclimate.com/repos/1/vulnerabilities\">critical</a>",
      "issues found.",
    ].join(" "))
  end

  private

  def assert_hipchat_receives(event_name, color, event_data, expected_body)
    @stubs.post '/v1/rooms/message' do |env|
      body = Hash[URI.decode_www_form(env[:body])]
      assert_equal "token", body["auth_token"]
      assert_equal "123", body["room_id"]
      assert_equal "true", body["notify"]
      assert_equal color, body["color"]
      assert_equal expected_body, body["message"]
      [200, {}, '']
    end

    receive(
      CC::Service::HipChat,
      event_name,
      { auth_token: "token", room_id: "123", notify: true },
      event_data
    )
  end
end
