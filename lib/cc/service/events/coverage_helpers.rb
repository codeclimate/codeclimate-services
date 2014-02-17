module CC::Service::CoverageHelpers
  def repo_name
    payload["repo_name"]
  end

  def details_url
    payload["details_url"]
  end

  def improved?
    covered_delta_percent > 0
  end

  def emoji
    if improved?
      ":sunny:"
    else
      ":umbrella:"
    end
  end

  def changed
    if improved?
      "improved"
    else
      "declined"
    end
  end

  def delta
    if improved?
      "+#{covered_delta_percent}%"
    else
      "#{covered_delta_percent}%"
    end
  end

  def covered_percent
    payload.fetch("covered_percent", 0).round(1)
  end

  def previous_covered_percent
    payload.fetch("previous_covered_percent", 0).round(1)
  end

  def covered_delta_percent
    (covered_percent - previous_covered_percent).round(1)
  end
end
