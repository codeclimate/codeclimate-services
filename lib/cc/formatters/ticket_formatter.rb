module CC
  module Formatters
    class TicketFormatter < CC::Service::Formatter
      def format_vulnerability_title
        if multiple?
          "#{vulnerabilities.size} new #{warning_type} issues found"
        else
          "New #{warning_type} issue found" << location_info
        end
      end

      def format_vulnerability_body
        if multiple?
          "#{vulnerabilities.size} new #{warning_type} issues were found by Code Climate"
        else
          message = "A #{warning_type} vulnerability was found by Code Climate"
          message << location_info
        end

        message << ".\n\n"
        message << details_url
      end
    end
  end
end
