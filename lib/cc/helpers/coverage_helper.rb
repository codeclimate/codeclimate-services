module CC::Service::CoverageHelper
  def improved?
    covered_percent_delta > 0
  end

  def delta
    if improved?
      "+#{covered_percent_delta.round(1)}%"
    else
      "#{covered_percent_delta.round(1)}%"
    end
  end

  def covered_percent
    payload.fetch("covered_percent", 0).round(1)
  end

  def previous_covered_percent
    payload.fetch("previous_covered_percent", 0).round(1)
  end

  def covered_percent_delta
    payload.fetch("covered_percent_delta", 0) # pre-rounded
  end
end
