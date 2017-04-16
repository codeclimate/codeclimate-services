# Code Climate Services

[![Code Climate](https://codeclimate.com/github/codeclimate/codeclimate-services/badges/gpa.svg)](https://codeclimate.com/github/codeclimate/codeclimate-services)
[![Test Coverage](https://codeclimate.com/github/codeclimate/codeclimate-services/badges/coverage.svg)](https://codeclimate.com/github/codeclimate/codeclimate-services)

A collection of classes, each responsible for integrating one external service
with the Code Climate system.

## Overview

Services define `#receive_<event>` methods for any events they are interested
in. These methods will be invoked with `@payload` set to a hash of data about
the event being handled.

The structure of this data is described below. Note that there may be additional
keys not listed here.

## Events

Attributes common to all event types:

```javascript
{
  "repo_name": String,
  "details_url": String
}
```

### Coverage

Event name: `coverage`

Event-specific attributes:

```javascript
{
  "covered_percent": Float,
  "previous_covered_percent": Float,
  "covered_percent_delta": Float,
  "compare_url": String
}
```

### Quality

Event name: `quality`

Event-specific attributes:

```javascript
{
  "constant_name": String,
  "rating": String, // "A", "B", "C", etc
  "previous_rating": String,
  "remediation_cost": Float,
  "previous_remediation_cost": Float,
  "compare_url": String
}
```

### Vulnerability

Event name: `vulnerability`

Event-specific attributes:

```javascript
{
  "warning_type": String,
  "vulnerabilities": [{
    "warning_type": String,
    "location": String
  }, {
    // ...
  }]
}
```

*Note*: The reason for the top-level `warning_type` attribute is for when the
list of vulnerabilities are of mixed warning types. In this case, the top-level
attribute can be used in any messaging.

### Pull Request

Event name: `pull_request`

Event-specific attributes:

```javascript
{
  "state": String, // "pending", or "success"
  "github_slug": String, // user/repo
  "number": String,
  "commit_sha": String,
}
```

### Pull Request Coverage

Event name: `pull_request_coverage`

Event-specific attributes:

```javascript
{
  "state": String, // "pending", "success", or "failure"
  "github_slug": String, // user/repo
  "number": String,
  "commit_sha": String,
  "covered_percent_delta": Float,
}
```

## Other Events

The following are not fully implemented yet.

* `snapshot`

## Contributing

To add a new integration, you'll need to create a new `Service` subclass. Please
use existing services as an example:

- Chat service examples: [hipchat](lib/cc/services/hipchat.rb), [campfire](lib/cc/services/campfire.rb)
- Issue tracker examples: [github_issues](lib/cc/services/github_issues.rb), [lighthouse](lib/cc/services/lighthouse.rb)

Ensure that your class implements `#receive_test`. It must handle any exceptions
and always return a hash of `{ ok: true|false, message: "String (HTML ok)" }`.
[Example](lib/cc/services/jira.rb#L31).

When you open your PR, please include an image for your service.

## License

See LICENSE.txt. This incorporates code from bugsnag-notification-plugins and
github-services, both MIT licensed.  
