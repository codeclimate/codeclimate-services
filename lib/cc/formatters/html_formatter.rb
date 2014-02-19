module CC
  module Formatters
    class HtmlFormatter < CC::Service::Formatter
      def format_test
        message = message_prefix
        message << "This is a test of the #{service_title} service hook"
      end

      def format_coverage
        message = message_prefix
        message << "<a href=\"#{details_url}\">Test coverage</a>"
        message << " has #{changed} to #{covered_percent}% (#{delta})"

        if compare_url
          message << " (<a href=\"#{compare_url}\">Compare</a>)"
        end

        message
      end

      def format_quality
        message = message_prefix
        message << "<a href=\"#{details_url}\">#{constant_name}</a>"
        message << " has #{changed} from #{previous_rating} to #{rating}"

        if compare_url
          message << " (<a href=\"#{compare_url}\">Compare</a>)"
        end

        message
      end

      def format_vulnerability
        message = message_prefix

        if multiple?
          message << "#{vulnerabilities.size} new"
          message << " <a href=\"#{details_url}\">#{warning_type}</a>"
          message << " issues found"
        else
          message << "New <a href=\"#{details_url}\">#{warning_type}</a>"
          message << " issue found"
          message << location_info
        end

        message
      end
    end
  end
end
