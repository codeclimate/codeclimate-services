#!/usr/bin/env ruby
#
# Ad-hoc script for sending the test event to service classes
#
# Usage:
#
#   $ <SERVICE>_<CONFIG_ATTR_1>="..." \
#     <SERVICE>_<CONFIG_ATTR_2>="..." \
#     ... ... bundle exec ruby service_test.rb
#
# Example:
#
#   $ SLACK_WEBHOOK_URL="http://..." bundle exec ruby service_test.rb
#   $ GITHUBPULLREQUESTS_UPDATE_STATUS=false GITHUBPULLREQUESTS_OAUTH_TOKEN=06083a4a060d358ca709939b1f00645777661c44 bundle exec ruby service_test.rb
#
# Other Environment variables used:
#
#   REPO_NAME  Defaults to "App"
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

class ServiceTest
  def initialize(klass, *params)
    @klass = klass
    @params = params
  end

  def test(payload = {})
    config = {}

    puts "-"*80
    puts @klass

    @params.each do |param|
      if var = ENV[to_env_var(param)]
        config[param] = var
      else
        puts "  -> skipping"
        return false
      end
    end

    puts "  -> testing"
    puts "  -> #{config.inspect}"
    print "  => "

    test_service(@klass, config, payload)
  end

private

  def to_env_var(param)
    "#{@klass.to_s.split("::").last}_#{param}".upcase
  end

  def test_service(klass, config, payload)
    repo_name = ENV["REPO_NAME"] || "App"

    service = klass.new(
      config,
      { name: :test, repo_name: repo_name }.merge(payload)
    )

    CC::Service::Invocation.new(service) do |i|
      i.wrap(WithResponseLogging)
    end
  end
end

ServiceTest.new(CC::Service::Slack, :webhook_url).test
ServiceTest.new(CC::Service::Flowdock, :api_token).test
ServiceTest.new(CC::Service::Jira, :username, :password, :domain, :project_id).test
ServiceTest.new(CC::Service::Asana, :api_key, :workspace_id, :project_id).test
ServiceTest.new(CC::Service::GitHubPullRequests, :oauth_token).test({ github_slug: "codeclimate/codeclimate" })
