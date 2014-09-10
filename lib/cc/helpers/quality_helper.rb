module CC::Service::QualityHelper
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

  def with_article(letter, bold = false)
    letter ||= '?'

    text = bold ? "*#{letter}*" : letter
    if %w( A F ).include?(letter.to_s)
      "an #{text}"
    else
      "a #{text}"
    end
  end

  def constant_basename(name)
    if name.include?(".")
      File.basename(name)
    else
      name
    end
  end
end
