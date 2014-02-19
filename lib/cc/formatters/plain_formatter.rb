module CC
  module Formatters
    class PlainFormatter < CC::Service::Formatter
      def format_test
        message = message_prefix
        message << "This is a test of the #{service_title} service hook"
      end

      def format_coverage
        message = message_prefix
        message << "#{emoji} Test coverage has #{changed}"
        message << " to #{covered_percent}% (#{delta})."
        message << " (#{details_url})"
      end

      def format_quality
        message = message_prefix
        message << "#{emoji} #{constant_name} has #{changed}"
        message << " from #{previous_rating} to #{rating}."
        message << " (#{details_url})"
      end

      def format_vulnerability
        message = message_prefix

        if multiple?
          message << "#{vulnerabilities.size} new #{warning_type} issues found"
        else
          message << "New #{warning_type} issue found" << location_info
        end

        message << ". Details: #{details_url}"
      end
    end
  end
end
