module CC
  module Services
    def version
      path = File.expand_path("../../../../VERSION", __FILE__)
      @version ||= File.read(path).strip
    end
    module_function :version
  end
end
