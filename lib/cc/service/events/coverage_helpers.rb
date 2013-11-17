module CC::Service::CoverageHelpers
  def coverage
    payload["coverage"]
  end

  def self.sample_payload
    {
      coverage: 80.3
    }
  end
end

