class EventFixtures
  attr_reader :options

  REMEDIATIONS = {
    "A" => 0,
    "B" => 10,
    "C" => 15,
    "D" => 20,
    "F" => 25,
  }.freeze

  def initialize(options)
    @options = {
      repo_name: "Example",
      details_url: "https://codeclimate.com/repos/1/feed",
      compare_url: "https://codeclimate.com/repos/1/compare",
    }.merge(options)
  end

  # Options: to, from
  def coverage
    to = options.delete(:to)
    from = options.delete(:from)
    delta = (to - from).round(1)

    options.merge(
      name: "coverage",
      covered_percent: to,
      previous_covered_percent: from,
      covered_percent_delta: delta,
    )
  end

  # Options: to, from
  def quality
    to = options.delete(:to)
    from = options.delete(:from)

    options.merge(
      name: "quality",
      constant_name: "User",
      rating: to,
      previous_rating: from,
      remediation_cost: REMEDIATIONS[to],
      previous_remediation_cost: REMEDIATIONS[from],
    )
  end

  # Options: warning_type, vulnerabilities
  def vulnerability
    options.merge(name: "vulnerability")
  end

  def issue
    options.merge(name: "issue")
  end
end

def event(name, options = {})
  fixtures = EventFixtures.new(options)

  if fixtures.respond_to?(name)
    fixtures.send(name)
  else
    raise ArgumentError, "No such fixture: #{name}"
  end
end
