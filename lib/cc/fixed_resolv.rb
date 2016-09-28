require "resolv-replace"

module CC
  class FixedResolv < Resolv::DNS
    def self.enable!
      new.tap do |instance|
        Resolv::DefaultResolver.replace_resolvers([instance])
      end
    end

    def initialize
      @addresses = {}
    end

    def setaddress(name, address)
      addresses[name] = address
    end

    def each_address(name)
      if addresses.key?(name)
        yield addresses.fetch(name)
      end
    end

    private

    attr_reader :addresses
  end
end
