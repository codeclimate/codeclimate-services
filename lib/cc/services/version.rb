module CC
  module Services
    def version
      path = File.expand_path("../../../VERSION", __FILE__)
      @version ||= File.read(path)
    end
  end
end
