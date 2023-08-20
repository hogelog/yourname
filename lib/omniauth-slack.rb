module OmniAuth
  module Strategies
    class Slack < OmniAuth::Strategies::OAuth2
      option :name, "slack"

      option :client_options, {
        site: "https://slack.com",
        authorize_url: "https://slack.com/oauth/v2/authorize",
        token_url: "https://slack.com/api/oauth.v2.access",
      }

      option :authorize_params, {
        scope: "users:read,users:read.email",
      }

      def callback_url
        full_host + callback_path
      end

      uid do
        @uid ||= access_token.response.parsed.authed_user.id
      end

      info do
        {
          name: raw_info.name,
          email: raw_info.profile.email,
          real_name: raw_info.real_name,
          image: raw_info.profile.image_512,
        }
      end

      extra do
        {
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/users.info?user=#{ uid }").parsed.user
      end
      #
      # def email
      #   raw_info.profile.email
      # end
      #
      # def scope
      # end
    end
  end
end
