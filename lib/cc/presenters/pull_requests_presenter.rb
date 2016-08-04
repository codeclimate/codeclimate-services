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

      def coverage_success_message
        "Test coverage for this commit: #{@covered_percent}%"
      end

      def success_message
        if both_issue_counts_zero?
          "Code Climate didn't find any new or fixed issues."
        else
          "Code Climate found #{formatted_issue_counts}."
        end
      end

    private

      def both_issue_counts_zero?
        issue_counts.all?(&:zero?)
      end

      def formatted_fixed_issues
        if @fixed_count > 0
          "#{number_to_delimited(@fixed_count)} fixed #{"issue".pluralize(@fixed_count)}"
        else
          nil
        end
      end

      def formatted_new_issues
        if @new_count > 0
          "#{number_to_delimited(@new_count)} new #{"issue".pluralize(@new_count)}"
        else
          nil
        end
      end

      def formatted_issue_counts
        [formatted_new_issues, formatted_fixed_issues].compact.to_sentence
      end

      def issue_counts
        [@new_count, @fixed_count]
      end
    end
  end
end
