#!/usr/bin/env ruby
#
# Ad-hoc script for sending the test event to service classes
#
###
require 'cc/services'
CC::Service.load_services

def test_service(klass, config)
  service = klass.new(:test, config, { repo_name: "Example" })
  service.receive
end

test_service(CC::Service::Slack, {
  webhook_url: "...",
  channel: "..."
})
