module CC
  class Service
    class PullRequestsPresenter
      include ActiveSupport::NumberHelper

      def initialize(payload)
        issue_comparison_counts = payload["issue_comparison_counts"]

        if issue_comparison_counts
          @fixed_count = issue_comparison_counts["fixed"]
          @new_count = issue_comparison_counts["new"]
        end

        @covered_percent = payload["covered_percent"]
        @covered_percent_delta = payload["covered_percent_delta"]

        @approved_by = payload["approved_by"].presence
      end

      def approved_message
        "Approved by #{@approved_by}."
      end

      def error_message
        "Code Climate encountered an error attempting to analyze this pull request."
      end

      def pending_message
        "Code Climate is analyzing this code."
      end

      def skipped_message
        "Code Climate has skipped analysis of this commit."
      end

      def coverage_message
        message = "#{formatted_percent(@covered_percent)}%"

        if @covered_percent_delta > 0
          message += " (+#{formatted_percent(@covered_percent_delta)}%)"
        elsif @covered_percent_delta < 0
          message += " (#{formatted_percent(@covered_percent_delta)}%)"
        end

        message
      end

      def success_message
        if @approved_by
          approved_message
        elsif @new_count > 0 && @fixed_count > 0
          "#{@new_count} new #{"issue".pluralize(@new_count)} (#{@fixed_count} fixed)"
        elsif @new_count <= 0 && @fixed_count > 0
          "#{@fixed_count} fixed #{"issue".pluralize(@fixed_count)}"
        elsif @new_count > 0 && @fixed_count <= 0
          "#{@new_count} new #{"issue".pluralize(@new_count)}"
        else
          "no new or fixed issues"
        end
      end

      private

      def formatted_percent(value)
        "%g" % ("%.2f" % value)
      end
    end
  end
end
