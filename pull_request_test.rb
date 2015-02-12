#!/usr/bin/env ruby
#
# Ad-hoc script for updating a pull request using our service.
#
# Usage:
#
#   $ OAUTH_TOKEN="..." bundle exec ruby pull_request_test.rb
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

service = CC::Service::GitHubPullRequests.new({
  oauth_token:   ENV.fetch("OAUTH_TOKEN"),
}, {
  name:        "pull_request",
  # https://github.com/codeclimate/nillson/pull/33
  state:       "success",
  github_slug: "codeclimate/nillson",
  number:      33,
  commit_sha:  "986ec903b8420f4e8c8d696d8950f7bd0667ff0c"
})

CC::Service::Invocation.new(service) do |i|
  i.wrap(WithResponseLogging)
end

ghe_service = CC::Service::GithubEnterprisePullRequest.new({
  oauth_token: ENV.fetch("OAUTH_TOKEN"),
  base_url: ENV.fetch("GITHUB_BASE_URL"),
  ssl_verification: false
}, {
  name:        "pull_request",
  state:       "success",
  github_slug: ENV.fetch("GITHUB_SLUG"),
  number:      ENV.fetch("GITHUB_PR_NUMBER"),
  commit_sha:  ENV.fetch("GITHUB_COMMIT_SHA")
})

CC::Service::Invocation.new(ghe_service) do |i|
  i.wrap(WithResponseLogging)
end
