module CC
  module Formatters
    # TODO: this differs with HtmlFormatter only in how links are
    # rendered. I hesitate to add more to the Object graph to provide
    # that seam.
    class WikiFormatter < CC::Service::Formatter
      def format_test
        message = message_prefix
        message << "This is a test of the #{service_title} service hook"
      end

      def format_coverage
        message = message_prefix
        message << "<#{details_url}|Test coverage>"
        message << " has #{changed} to #{covered_percent}% (#{delta})"

        if compare_url
          message << " (<#{compare_url}|Compare>)"
        end

        message
      end

      def format_quality
        message = message_prefix
        message << "<#{details_url}|#{constant_name}>"
        message << " has #{changed} from #{previous_rating} to #{rating}"

        if compare_url
          message << " (<#{compare_url}|Compare>)"
        end

        message
      end

      def format_vulnerability
        message = message_prefix

        if multiple?
          message << "#{vulnerabilities.size} new"
          message << " <#{details_url}|#{warning_type}>"
          message << " issues found"
        else
          message << "New <#{details_url}|#{warning_type}>"
          message << " issue found"
          message << location_info
        end

        message
      end
    end
  end
end
