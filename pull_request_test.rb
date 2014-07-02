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
  update_status: true,
  add_comment:   true,
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
