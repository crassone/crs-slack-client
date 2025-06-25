# frozen_string_literal: true

require "crs/slack/client"
require "vcr"
require "webmock/rspec"

# VCRの設定
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # APIトークンなどの機密情報をフィルタリング
  config.filter_sensitive_data("<SLACK_API_TOKEN>") do |interaction|
    # Authorizationヘッダーからトークンを抽出してマスク
    auth_header = interaction.request.headers["Authorization"]&.first
    if auth_header
      match = auth_header.match(/Bearer (.+)/)
      match[1] if match
    end
  end

  # カスタムリクエストマッチャーの定義
  # チャンネル名のタイムスタンプ部分を無視するマッチャー
  config.register_request_matcher :slack_body_matcher do |request1, request2|
    # URIとメソッドが一致するか確認
    if request1.uri == request2.uri && request1.method == request2.method
      # リクエストボディがない場合は通常の比較
      if request1.body.nil? || request2.body.nil?
        request1.body == request2.body
      # チャンネル作成・招待・アーカイブのリクエストの場合
      elsif request1.uri.to_s.include?("conversations.create") ||
            request1.uri.to_s.include?("conversations.invite") ||
            request1.uri.to_s.include?("conversations.archive")
        # タイムスタンプを含むチャンネル名のパターンを無視
        body1 = request1.body.to_s.gsub(/name=vcr[^&]+/, "name=vcr-test")
        body2 = request2.body.to_s.gsub(/name=vcr[^&]+/, "name=vcr-test")
        body1 == body2
      else
        # その他のリクエストは通常の比較
        request1.body == request2.body
      end
    else
      false
    end
  end

  # リクエストのマッチング設定
  config.default_cassette_options = {
    record: :once,               # 最初の実行時のみ記録
    match_requests_on: [
      :method,                   # HTTPメソッド
      :uri,                      # URI
      :slack_body_matcher        # カスタムボディマッチャー
    ],
    allow_playback_repeats: true # 同じリクエストの再生を許可
  }
end

# テスト用のヘルパーメソッド
module SlackApiHelpers
  # テスト用のAPIトークン
  def test_api_token
    ENV.fetch("SLACK_API_TOKEN", "dummy-token-for-testing")
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # ヘルパーメソッドをインクルード
  config.include SlackApiHelpers
end
