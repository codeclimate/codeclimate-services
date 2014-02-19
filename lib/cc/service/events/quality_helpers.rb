module CC::Service::QualityHelpers
  def improved?
    remediation_cost < previous_remediation_cost
  end

  def constant_name
    payload["constant_name"]
  end

  def rating
    with_article(payload["rating"])
  end

  def previous_rating
    with_article(payload["previous_rating"])
  end

  def remediation_cost
    payload.fetch("remediation_cost", 0)
  end

  def previous_remediation_cost
    payload.fetch("previous_remediation_cost", 0)
  end

  def with_article(letter)
    letter ||= '?'

    if %w( A F ).include?(letter)
      "an #{letter}"
    else
      "a #{letter}"
    end
  end
end
