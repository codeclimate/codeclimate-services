class CC::Service::Invocation
  RETRIES = 3

  def initialize(service, statsd = nil, logger = nil)
    @service = service
    @statsd = statsd || NullObject.new
    @logger = logger || NullObject.new
  end

  def invoke
    safely { service.receive }

    statsd.increment(success_stat)
  end

  private

  attr_reader :service, :statsd, :logger

  def safely(&block)
    with_retries(RETRIES, &block)
  rescue => ex
    statsd.increment(error_stat(ex))
    logger.error(error_message(ex))
  end

  def with_retries(retries, &block)
    yield

  rescue => ex
    raise ex if retries.zero?

    retries -= 1
    retry
  end

  def success_stat
    "services.invocations.#{service.slug}"
  end

  def error_stat(ex)
    "services.errors.#{service.slug}.#{ex.class.name.underscore}"
  end

  def error_message(ex)
    "Exception invoking #{service.slug} service: (#{ex.class}) #{ex.message}"
  end

  class NullObject
    def method_missing(*)
    end
  end
end
