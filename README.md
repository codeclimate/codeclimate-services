# Code Climate Services

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

## Other Events

The following are not fully implemented yet.

* :issue
* :unit
* :snapshot

## License

See LICENSE.txt. This incorporates code from bugsnag-notification-plugins and
github-services, both MIT licensed.
