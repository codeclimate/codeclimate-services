#!/usr/bin/env ruby
#
# Ad-hoc script for sending the test event to service classes
#
# Usage:
#
#   bundle exec ruby service_test.rb
#
# Environment variables used:
#
#   REPO_NAME           Defaults to "App"
#   SLACK_WEBHOOK_URL   Slack is not tested unless set
#   FLOWDOCK_API_TOKEN  Flowdock is not tested unless set
#
# Example:
#
#   SLACK_WEBHOOK_URL="http://..." bundle exec ruby service_test.rb
#
###
require 'cc/services'
CC::Service.load_services

class WithResponseLogging
  def initialize(invocation)
    @invocation = invocation
  end

  def call
    @invocation.call.tap { |r| p r }
  end
end

def test_service(klass, config)
  repo_name = ENV["REPO_NAME"] || "App"

  service = klass.new(config, name: :test, repo_name: repo_name)

  CC::Service::Invocation.new(service) do |i|
    i.wrap(WithResponseLogging)
  end
end

if webhook_url = ENV["SLACK_WEBHOOK_URL"]
  puts "Testing Slack..."
  test_service(CC::Service::Slack, webhook_url: webhook_url)
end

if api_token = ENV["FLOWDOCK_API_TOKEN"]
  puts "Testing Flowdock..."
  test_service(CC::Service::Flowdock, api_token: api_token)
end

if (jira_username = ENV["JIRA_USERNAME"]) &&
   (jira_password = ENV["JIRA_PASSWORD"]) &&
   (jira_domain   = ENV["JIRA_DOMAIN"])   &&
   (jira_project  = ENV["JIRA_PROJECT"])
  puts "Testing Jira"
  test_service(CC::Service::Jira, { username:   jira_username,
                                    password:   jira_password,
                                    domain:     jira_domain,
                                    project_id: jira_project })
end
