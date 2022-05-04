#! /usr/bin/env ruby
#
# Parse Brakeman JSON report and reformat for Bitbitbucket.
#
# Author: Robert James Kaes <rjk@wormbytes.ca>
#
# Usage: report.parse.brakeman.rb report.json
#

require 'json'

SEVERITY_TO_BITBUCKET = {
  'High' => 'HIGH',
  'Medium' => 'MEDIUM',
  'Weak' => 'LOW',
}

report = JSON.parse(ARGF.read)

metadata = {
  title: 'Brakeman',
  details: 'Brakeman Security Scan',
  report_type: 'SECURITY',
  logo_url: 'https://brakemanscanner.org/images/brakeman_logo_small.png',
  data: [
    {
      title: 'Warnings',
      type: 'NUMBER',
      value: report.fetch('scan_info').fetch('security_warnings'),
    },
  ],
}

annotations = []

errors = report.fetch('errors')
errors.each_with_index do |error, idx|
  file, line = error.values_at('file', 'line')

  annotations << {
    annotation_type: 'VULNERABILITY',
    external_id: "#{file}-offense-#{idx}",
    path: file,
    line: line,
    summary: format('[%s] %s', *error.values_at('warning_type', 'message')),
    severity: 'CRITICAL',
  }
end

warnings = report.fetch('warnings')
warnings.each_with_index do |warning, idx|
  file, line = warning.values_at('file', 'line')

  annotations << {
    annotation_type: 'VULNERABILITY',
    external_id: "#{file}-offense-#{idx}",
    path: file,
    line: line,
    summary: format('[%s] %s', *warning.values_at('warning_type', 'message')),
    severity: SEVERITY_TO_BITBUCKET[warning.fetch('confidence')],
  }
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
