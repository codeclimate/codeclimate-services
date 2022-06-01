require "delegate"

class CC::Service::Formatter < SimpleDelegator
  attr_reader :options

  def initialize(service, options = {})
    super(service)

    @options = {
      prefix: "[Code Climate]",
      prefix_with_repo: true,
    }.merge(options)
  end

  private

  def service_title
    __getobj__.class.title
  end

  def message_prefix
    prefix = options.fetch(:prefix, "").to_s.dup

    if options[:prefix_with_repo]
      prefix << "[#{repo_name}]"
    end

    unless prefix.empty?
      prefix << " "
    end

    prefix
  end
end
