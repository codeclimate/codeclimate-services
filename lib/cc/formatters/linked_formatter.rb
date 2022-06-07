module CC
  module Formatters
    class LinkedFormatter < CC::Service::Formatter
      def format_test
        # test something
        message = message_prefix
        message << "This is a test of the #{service_title} service hook"
      end

      def format_coverage
        message = message_prefix
        message << format_link(details_url, "Test coverage").to_s
        message << " has #{changed} to #{covered_percent}% (#{delta})"

        if compare_url
          message << " (#{format_link(compare_url, "Compare")})"
        end

        message
      end

      def format_quality
        message = message_prefix
        message << format_link(details_url, constant_name).to_s
        message << " has #{changed} from #{previous_rating} to #{rating}"

        if compare_url
          message << " (#{format_link(compare_url, "Compare")})"
        end

        message
      end

      def format_vulnerability
        message = message_prefix

        if multiple?
          message << "#{vulnerabilities.size} new"
          message << " #{format_link(details_url, warning_type)}"
          message << " issues found"
        else
          message << "New #{format_link(details_url, warning_type)}"
          message << " issue found"
          message << location_info
        end

        message
      end

      private

      def format_link(url, text)
        case options[:link_style]
        when :html then "<a href=\"#{url}\">#{text}</a>"
        when :wiki then "<#{url}|#{text}>"
        else text
        end
      end
    end
  end
end
