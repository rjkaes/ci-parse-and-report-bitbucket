#! /usr/bin/env ruby
#
# Parse Rubocop JSON report and reformat for Bitbitbucket.
#
# Author: Robert James Kaes <rjk@wormbytes.ca>
#
# Usage: report.parse.rubocop.rb report.json
#

require 'json'

SEVERITY_TO_BITBUCKET = {
  'info' => 'LOW',
  'refactor' => 'LOW',
  'convention' => 'MEDIUM',
  'warning' => 'HIGH',
  'error' => 'CRITICAL',
  'fatal' => 'CRITICAL',
}

report = JSON.parse(ARGF.read)

metadata = {
  title: 'Rubocop',
  details: 'Rubocop Linting Scan',
  report_type: 'COVERAGE',
  logo_url: 'https://raw.githubusercontent.com/rubocop/rubocop/master/logo/rubo-logo-symbol.png',
  data: [
    {
      title: 'Offense Count',
      type: 'NUMBER',
      value: report.fetch('summary').fetch('offense_count'),
    },
  ],
}

files = report.fetch('files')
annotations = []

files.each do |info|
  path = info.fetch('path')
  offenses = info.fetch('offenses')
  offenses.each_with_index do |offense, idx|
    annotations << {
      external_id: "#{path}-offense-#{idx}",
      path: path,
      line: offense.fetch('location').fetch('line'),
      summary: format('[%s] %s', *offense.values_at('cop_name', 'message')),
      severity: SEVERITY_TO_BITBUCKET[offense.fetch('severity')],
      annotation_type: 'CODE_SMELL',
    }
  end
end

# Bitbucket can only handle 1000 annotations per report.  Therefore, group the
# annotations by severity so the most critical are always shown.
submitted_annotations = annotations
  .group_by { |obj| obj[:severity] }
  .values_at('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')
  .flatten
  .compact
  .first(1000)

output = {
  report: metadata,
  annotations: submitted_annotations,
}

JSON.dump(output, $stdout)
