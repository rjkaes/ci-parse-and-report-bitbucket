#! /usr/bin/env ruby
#
# Send the report to Bitbucket.
#
# Author: Robert James Kaes <rjk@wormbytes.ca>
#
# Usage: submit_report_to_bitbucket.rb repo-slug report-name parsed.report.json
#
# Required Environment Variables:
#
#   `BITBUCKET_WORKSPACE`
#   `BITBUCKET_USER`
#   `BITBUCKET_PASSWORD`
#   `GIT_COMMIT`
#

require 'json'
require 'net/http'
require 'uri'

# Package up the request and send it to the URL with HTTP basic auth enabled.
def send_request_to(request, url)
  user = ENV.fetch('BITBUCKET_USER')
  password = ENV.fetch('BITBUCKET_PASSWORD')

  request.basic_auth(user, password)

  Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
    http.request(request)
  end
end

repo_slug = ARGV.shift
report = ARGV.shift

# Jenkins defines this for each "build"
revision = ENV.fetch('GIT_COMMIT')

workspace = ENV.fetch('BITBUCKET_WORKSPACE')

base_url = URI("https://api.bitbucket.org/2.0/repositories/#{workspace}/#{repo_slug}/commit/#{revision}/reports/#{report}")

# Load up the JSON report (as parsed by `report.parse.*` scripts)
report = JSON.parse(ARGF.read)

# Delete any previous report
req = Net::HTTP::Delete.new(base_url)
req['X-Atlassian-Token'] = 'no-check'
send_request_to(req, base_url)

# Create the report
req = Net::HTTP::Put.new(base_url)
req.body = JSON.generate(report.fetch('report'))
req.content_type = 'application/json'
send_request_to(req, base_url)

# Create new annotations.  The bitbucket API can only accept 100 annotations at
# a time in the POST JSON body.
annotations = report.fetch('annotations')
annotations.each_slice(100) do |slice|
  url = URI("#{base_url}/annotations")
  req = Net::HTTP::Post.new(url)
  req.content_type = 'application/json'
  req.body = JSON.generate(slice)

  send_request_to(req, url)
end
