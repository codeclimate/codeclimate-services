module CC::Service::IssueHelper
  def constant_name
    payload["constant_name"]
  end

  def issue
    payload["issue"]
  end
end
