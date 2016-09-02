class FakeLogger
  attr_reader :logged_errors

  def initialize
    @logged_errors = []
  end

  def error(message)
    @logged_errors << message
  end
end
