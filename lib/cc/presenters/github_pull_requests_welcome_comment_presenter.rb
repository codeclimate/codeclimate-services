module CC
  class Service
    class GitHubPullRequestsWelcomeCommentPresenter
      INTRODUCTION_TEMPLATE = <<-HEADER.freeze
Hey, @%s -- Since this is the first PR we've seen from you, here's some things you should know about contributing to **%s**:
      HEADER

      DEFAULT_BODY = <<-COMMENT.freeze
* This repository is using Code Climate to automatically check for code quality issues.
* You can see results for this analysis in the PR status below.
* You can install [the Code Climate browser extension](https://codeclimate.com/browser) to see analysis without leaving GitHub.

Thanks for your contribution!
      COMMENT

      ADMIN_ONLY_FOOTER_TEMPLATE = <<-FOOTER.freeze
* * *
Quick note: By default, Code Climate will post the above comment on the *first* PR it sees from each contributor. If you'd like to customize this message or disable this, go [here](%s).
      FOOTER

      def initialize(payload, config)
        @payload = payload
        @config = config
      end

      def welcome_message
        if author_can_administrate_repo?
          welcome_comment_introduction + welcome_comment_body + welcome_comment_footer
        else
          welcome_comment_introduction + welcome_comment_body
        end
      end

      private

      attr_reader :payload, :config

      def author_can_administrate_repo?
        payload.fetch("author_can_administrate_repo")
      end

      def author_username
        payload.fetch("author_username")
      end

      def github_slug
        payload.fetch("github_slug")
      end

      def welcome_comment_introduction
        format INTRODUCTION_TEMPLATE, author_username, github_slug
      end

      def welcome_comment_body
        config.welcome_comment_markdown
      end

      def welcome_comment_footer
        format ADMIN_ONLY_FOOTER_TEMPLATE, @payload.fetch("pull_request_integration_edit_url")
      end
    end
  end
end
