module CC
  class Service
    ConfigurationError = Class.new(StandardError)

    class Config
      include Virtus.model
      include ActiveModel::Validations
    end
  end
end
