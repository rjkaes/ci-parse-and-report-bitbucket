# Bitbucket Parse and Report

Parse [Rubocop](https://rubocop.org/) and [Brakeman](https://brakemanscanner.org/) reports and submit them to [Bitbucket](https://bitbucket.org/) to
annotate a PR or set of [git](https://git-scm.com/) commits.

Useful when integrating into a [CI](https://en.wikipedia.org/wiki/Continuous_integration) like [Jenkins](https://www.jenkins.io/)

## Getting Started

### Dependencies

Ruby plus rubocop and/or brakeman depending on which report you wish to submit.

You also need your Bitbucket credentials plus the name of the workspace.  For
example, viewing one of your repositories, you'll see a URL like:

```
https://bitbucket.org/WORKSPACE/REPO_SLUG/src/master/
```

Copy those parts and store them as `BITBUCKET_WORKSPACE` and `REPO_SLUG`

### Executing Example

Below is an example shell script that assumes it has been run from within a
typical [Rails](https://rubyonrails.org/) application.

```sh
# Required and typically comes from Jenkins when it runs as job
#   GIT_COMMIT

# Adjust to match your setup
export BITBUCKET_WORKSPACE='the-bitbucket-workspace'
export BITBUCKET_USER='username'
export BITBUCKET_PASSWORD='password'
export REPO_SLUG='the-repository'

# Submit Rubocop Report to Bitbucket (for a typical Rails application)
rubocop -c /opt/rubocop.yml --fail-level E --format json --out report.rubocop.json $(find app lib spec -name '*.rb' -print)
report.parse.rubocop.rb report.rubocop.json > parsed.report.rubocop.json
report.submit.rb $REPO_SLUG rubocop parsed.report.rubocop.json || true

# Submit Brakeman Report to Bitbucket
brakeman -A -f json -o report.brakeman.json --no-exit-on-warn --no-exit-on-error --force-scan
report.parse.brakeman.rb report.brakeman.json > parsed.report.brakeman.json
report.submit.rb $REPO_SLUG brakeman parsed.report.brakeman.json || true
```

## Authors

[Robert James Kaes](https://www.wormbytes.ca/)

## License

This project is licensed under the [MIT] License - see the LICENSE.txt file for details
