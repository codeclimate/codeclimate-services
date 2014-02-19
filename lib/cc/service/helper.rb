module CC::Service::Helper

  def repo_name
    payload["repo_name"]
  end

  def details_url
    payload["details_url"]
  end

  def compare_url
    payload["compare_url"]
  end

  def emoji
    if improved?
      ":sunny:"
    else
      ":umbrella:"
    end
  end

  def color
    if improved?
      "green"
    else
      "red"
    end
  end

  def changed
    if improved?
      "improved"
    else
      "declined"
    end
  end

  def improved?
    raise NotImplementedError,
      "Event-specific helpers must define #{__method__}"
  end

end
