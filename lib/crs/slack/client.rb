# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "debug"
require "logger"
require "net/http/post/multipart"
require "mime/types"
require "open-uri"
require "tempfile"
require "ostruct"
require_relative "client/version"

module Crs
  module Slack
    class Client
      SLACK_API_BASE_URL = "https://slack.com/api/"

      # SlackにPOSTする画像URLのクラス
      class ImageUrl < OpenStruct
        def initialize(url:, alt_text:)
          super(url: url, alt_text: alt_text)
        end
      end

      attr_accessor :logger, :api_token

      def initialize(api_token:)
        @logger = Logger.new($stdout)
        @api_token = api_token
      end

      # 指定したチャンネルにメッセージを送信する。
      # @param channel [String] チャンネルID
      # @param text [String] 送信するメッセージ
      def chat_post_message(channel:, text:)
        uri = URI.join(SLACK_API_BASE_URL, "chat.postMessage")
        params = {
          channel: channel,
          text: text
        }

        result = post(uri, params)

        unless result["ok"]
          logger.error("Error posting message: #{result["error"]}")
          raise "Slack API error: #{result["error"]}"
        end

        result
      rescue StandardError => e
        logger.error("Error posting message: #{e.message}")
        raise e
      end

      # rubocop:disable Metrics/MethodLength
      def add_reply(channel:, thread_ts:, image_urls:)
        uri = URI.join(SLACK_API_BASE_URL, "chat.postMessage")

        blocks = image_urls.map do |image_url|
          {
            type: "image",
            image_url: image_url.url,
            alt_text: image_url.alt_text
          }
        end

        params = {
          channel: channel,
          thread_ts: thread_ts,
          blocks: JSON.generate(blocks)
        }

        result = post(uri, params)
        unless result["ok"]
          logger.error("Error posting reply: #{result["error"]}")
          raise "Slack API error: #{result["error"]}"
        end
        result
      rescue StandardError => e
        logger.error("Error posting reply: #{e.message}")
        raise e
      end
      # rubocop:enable Metrics/MethodLength

      # SlackのDisplay Nameをキーとして、Slackユーザーの一覧を返す。
      # @return [Hash] Slackユーザーの一覧。
      # e.g) [ {"Slackbot" => {id: "USLACKBOT", display_name: "Slackbot", name: "slackbot", real_name: "Slackbot"}]
      def users_list
        # レスポンスのサンプル
        #
        # [ {"id" => "U08RW7MHUG6",
        # "name" => "user.name",
        # "is_bot" => false,
        # "updated" => 1747134377,
        # "is_app_user" => false,
        # "team_id" => "TJYFMDGA3",
        # "deleted" => false,
        # "color" => "bb86b7",
        # "is_email_confirmed" => true,
        # "real_name" => "ユーザー サンプル",
        # "tz" => "Asia/Tokyo",
        # "tz_label" => "Japan Standard Time",
        # "tz_offset" => 32400,
        # "is_admin" => false,
        # "is_owner" => false,
        # "is_primary_owner" => false,
        # "is_restricted" => true,
        # "is_ultra_restricted" => true,
        # "who_can_share_contact_card" => "EVERYONE",
        # "profile" =>
        #  {"real_name" => "ユーザー サンプル",
        #   "display_name" => "ユーザー サンプル",
        #   "avatar_hash" => "g082520283c2",
        #   "real_name_normalized" => "ユーザー サンプル",
        #   "display_name_normalized" => "ユーザー サンプル",
        #   "team" => "TJYFMDGA3",
        #   "first_name" => "ユーザー サンプル",
        #   "last_name" => "",
        #   "image_24" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=24&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-24.png",
        #   "image_32" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=32&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-32.png",
        #   "image_48" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=48&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-48.png",
        #   "image_72" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=72&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-72.png",
        #   "image_192" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-192.png",
        #   "image_512" => "https://secure.gravatar.com/avatar/082520283c26e8b0d1ae93797d7502b7.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0022-512.png",
        #   "status_text" => "",
        #   "status_text_canonical" => "",
        #   "status_emoji" => "",
        #   "status_emoji_display_info" => [],
        #   "status_expiration" => 0,
        #   "title" => "",
        #   "phone" => "",
        #   "skype" => ""}}]
        users = get("users.list")["members"]

        # real_name をキーとしてhashを作成
        hash = {}
        users.filter { |user| user["is_bot"] == false && user["deleted"] == false }.each do |user|
          # display_nameから半角・全角スペースを取り除く
          display_name = user["profile"]["display_name"].gsub(/[[:space:]]|\u3000/, "").strip
          next if display_name.empty? # display_nameが空の場合はスキップ

          hash[display_name] = {
            id: user["id"],
            display_name: display_name,
            name: user["name"],
            real_name: user["real_name"]
          }
        end

        hash
      rescue StandardError => e
        logger.error("Error fetching users: #{e.message}")
        raise e
      end

      private

      # Slack APIにGETリクエストを送信する
      def get(path, params = {})
        uri = URI.join(SLACK_API_BASE_URL, path)
        uri.query = URI.encode_www_form(params) unless params.empty?

        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{api_token}"
        request["Content-Type"] = "application/x-www-form-urlencoded"

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        result = JSON.parse(response.body)
        raise "Slack API error: #{result["error"]}" unless result["ok"]

        result
      end

      # Slack APIにPOSTリクエストを送信する
      def post(path, params = {})
        uri = URI.join(SLACK_API_BASE_URL, path)

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{api_token}"
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.set_form_data(params)

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        result = JSON.parse(response.body)
        raise "Slack API error: #{result["error"]}" unless result["ok"]

        result
      rescue StandardError => e
        logger.error("Error posting to Slack: #{e.message}")
        raise e
      end

      # def api_token
      #   @api_token ||= ENV['SLACK_API_TOKEN']
      # end
    end
  end
end
