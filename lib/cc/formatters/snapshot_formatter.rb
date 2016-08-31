module CC::Formatters
  module SnapshotFormatter
    # Simple Comparator for rating letters.
    class Rating
      include Comparable

      def initialize(letter)
        @letter = letter
      end

      def <=>(other)
        other.to_s <=> to_s
      end

      def hash
        @letter.hash
      end

      def eql?(other)
        to_s == other.to_s
      end

      def inspect
        "<Rating:#{self}>"
      end

      def to_s
        @letter.to_s
      end
    end

    C = Rating.new("C")
    D = Rating.new("D")

    # SnapshotFormatter::Base takes the quality information from the payload and divides it
    # between alerts and improvements.
    #
    # The information in the payload must be a comparison in time between two quality reports, aka snapshot.
    # This information is in the payload when the service receive a `receive_snapshot` and also
    # when it receives a `receive_test`. In this latest case, the comparison is between today and seven days ago.
    class Base
      attr_reader :alert_constants_payload, :improved_constants_payload, :details_url, :compare_url

      def initialize(payload)
        new_constants = Array(payload["new_constants"])
        changed_constants = Array(payload["changed_constants"])

        alert_constants = new_constants.select(&new_constants_selector)
        alert_constants += changed_constants.select(&decreased_constants_selector)

        improved_constants = changed_constants.select(&improved_constants_selector)

        data = {
          "from" => { "commit_sha" => payload["previous_commit_sha"] },
          "to"   => { "commit_sha" => payload["commit_sha"] },
        }

        @alert_constants_payload = data.merge("constants" => alert_constants) if alert_constants.any?
        @improved_constants_payload = data.merge("constants" => improved_constants) if improved_constants.any?
      end

      private

      def new_constants_selector
        proc { |constant| to_rating(constant) < C }
      end

      def decreased_constants_selector
        proc { |constant| from_rating(constant) > D && to_rating(constant) < C }
      end

      def improved_constants_selector
        proc { |constant| from_rating(constant) < C && to_rating(constant) > from_rating(constant) }
      end

      def to_rating(constant)
        Rating.new(constant["to"]["rating"])
      end

      def from_rating(constant)
        Rating.new(constant["from"]["rating"])
      end
    end

    # Override the base snapshot formatter for be more lax grouping information.
    # This is useful to show more information for testing the service.
    class Sample < Base
      def new_constants_selector
        proc { |_| true }
      end

      def decreased_constants_selector
        proc { |constant| to_rating(constant) < from_rating(constant) }
      end

      def improved_constants_selector
        proc { |constant| to_rating(constant) > from_rating(constant) }
      end
    end
  end
end
