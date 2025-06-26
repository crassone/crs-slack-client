# frozen_string_literal: true

RSpec.describe Crs::Slack::Client do
  let(:api_token) { "dummy-token" }
  let(:client) { described_class.new(api_token: api_token) }

  describe "#initialize" do
    it "セットしたapi_tokenを保持する" do
      expect(client.api_token).to eq(api_token)
    end
    it "loggerが標準出力に設定されている" do
      expect(client.logger).to be_a(Logger)
    end
  end

  # モックを使用した既存のテスト
  describe "#chat_post_message" do
    it "Slack APIにPOSTして結果を返す（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true, "ts" => "12345" })
      res = client.chat_post_message(channel: "C123", text: "hello")
      expect(res["ok"]).to be true
      expect(res["ts"]).to eq("12345")
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "invalid_auth" })
      expect do
        client.chat_post_message(channel: "C123", text: "hello")
      end.to raise_error(RuntimeError, /Slack API error/)
    end
  end

  describe "#add_reply" do
    it "画像付きリプライを送信できる（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true })
      image = Crs::Slack::Client::ImageUrl.new(url: "https://example.com/img.png", alt_text: "img")
      res = client.add_reply(channel: "C123", thread_ts: "12345", image_urls: [image])
      expect(res["ok"]).to be true
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "invalid_auth" })
      image = Crs::Slack::Client::ImageUrl.new(url: "https://example.com/img.png", alt_text: "img")
      expect do
        client.add_reply(channel: "C123", thread_ts: "12345", image_urls: [image])
      end.to raise_error(RuntimeError, /Slack API error/)
    end
  end

  describe "#users_list" do
    it "Slackユーザー一覧を返す（モック）" do
      fake_users = {
        "members" => [
          {
            "id" => "U1",
            "name" => "user1",
            "real_name" => "ユーザー1",
            "deleted" => false,
            "is_bot" => false,
            "profile" => { "display_name" => "ユーザー1" }
          },
          {
            "id" => "U2",
            "name" => "user2",
            "real_name" => "ユーザー2",
            "deleted" => true,
            "is_bot" => false,
            "profile" => { "display_name" => "削除済み" }
          },
          {
            "id" => "U3",
            "name" => "bot",
            "real_name" => "ボット",
            "deleted" => false,
            "is_bot" => true,
            "profile" => { "display_name" => "ボット" }
          }
        ]
      }
      allow(client).to receive(:get).and_return(fake_users)
      result = client.users_list
      expect(result.keys).to include("ユーザー1")
      expect(result.keys).not_to include("削除済み")
      expect(result.keys).not_to include("ボット")
      expect(result["ユーザー1"][:id]).to eq("U1")
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:get).and_raise(StandardError.new("API error"))
      expect do
        client.users_list
      end.to raise_error(StandardError, /API error/)
    end
  end

  describe "#conversations_create" do
    it "新しいチャンネルを作成できる（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true, "channel" => { "id" => "C12345" } })
      res = client.conversations_create(name: "new-channel")
      expect(res["ok"]).to be true
      expect(res["channel"]["id"]).to eq("C12345")
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "channel_already_exists" })
      expect do
        client.conversations_create(name: "existing-channel")
      end.to raise_error(Crs::Slack::Client::SlackApiError, /Error creating conversation/)
    end
  end

  describe "#conversations_invite" do
    it "チャンネルにユーザーを招待できる（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true })
      res = client.conversations_invite(channel: "C12345", users: %w[U1 U2])
      expect(res["ok"]).to be true
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "channel_not_found" })
      expect do
        client.conversations_invite(channel: "C12345", users: %w[U1 U2])
      end.to raise_error(Crs::Slack::Client::SlackApiError, /Error inviting users/)
    end
  end

  describe "#conversations_archive" do
    it "チャンネルをアーカイブできる（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true })
      res = client.conversations_archive(channel: "C12345")
      expect(res["ok"]).to be true
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "channel_not_found" })
      expect do
        client.conversations_archive(channel: "C12345")
      end.to raise_error(Crs::Slack::Client::SlackApiError, /Error archiving conversation/)
    end
  end

  describe Crs::Slack::Client::ImageUrl do
    it "urlとalt_textを持てる" do
      image = described_class.new(url: "https://example.com/img.png", alt_text: "img")
      expect(image.url).to eq("https://example.com/img.png")
      expect(image.alt_text).to eq("img")
    end
  end

  # VCRを使用したテスト
  describe "VCRを使用したAPIテスト" do
    let(:vcr_client) { described_class.new(api_token: test_api_token) }

    describe "#chat_post_message", vcr: { cassette_name: "slack/chat_post_message" } do
      it "メッセージを送信できる" do
        response = vcr_client.chat_post_message(
          channel: "C08TH1GJPUZ", # テスト用チャンネルID
          text: "VCRテスト: こんにちは！"
        )
        expect(response["ok"]).to be true
        expect(response["message"]["text"]).to eq("VCRテスト: こんにちは！")
      end
    end

    describe "#add_reply", vcr: { cassette_name: "slack/add_reply" } do
      it "スレッドに画像付きリプライを送信できる" do
        # まずメッセージを送信
        message = vcr_client.chat_post_message(
          channel: "C08TH1GJPUZ", # テスト用チャンネルID
          text: "VCRテスト: 画像付きリプライのテスト"
        )

        # 送信したメッセージのスレッドに画像付きリプライを送信
        image_url = Crs::Slack::Client::ImageUrl.new(
          url: "https://image.lgtmoon.dev/517710",
          alt_text: "LGTM画像"
        )

        response = vcr_client.add_reply(
          channel: "C08TH1GJPUZ",
          thread_ts: message["ts"],
          image_urls: [image_url]
        )

        expect(response["ok"]).to be true
        expect(response["message"]["thread_ts"]).to eq(message["ts"])
      end
    end

    describe "#users_list", vcr: { cassette_name: "slack/users_list" } do
      it "ユーザー一覧を取得できる" do
        users = vcr_client.users_list
        expect(users).to be_a(Hash)
        expect(users).not_to be_empty

        # 少なくとも1人のユーザーが含まれていることを確認
        first_user = users.values.first
        expect(first_user).to have_key(:id)
        expect(first_user).to have_key(:display_name)
        expect(first_user).to have_key(:name)
        expect(first_user).to have_key(:real_name)
      end
    end

    describe "#conversations_create", vcr: { cassette_name: "slack/conversations_create" } do
      it "チャンネルを作成できる" do
        # VCRカセットに合わせた固定のチャンネル名を使用
        channel_name = "vcr-test-1719288455"

        response = vcr_client.conversations_create(name: channel_name)
        expect(response["ok"]).to be true
        # チャンネル名が返されていることを確認（具体的な値は検証しない）
        expect(response["channel"]["name"]).not_to be_empty

        # テスト後にチャンネルをアーカイブ
        vcr_client.conversations_archive(channel: response["channel"]["id"])
      end
    end

    describe "#conversations_invite", vcr: { cassette_name: "slack/conversations_invite" } do
      it "チャンネルにユーザーを招待できる" do
        # VCRカセットに合わせた固定のチャンネル名を使用
        channel_name = "vcr-invite-test-1719288465"
        channel = vcr_client.conversations_create(name: channel_name)

        # ユーザー一覧を取得して最初のユーザーを招待
        users = vcr_client.users_list
        first_user_id = users.values.first[:id]

        response = vcr_client.conversations_invite(
          channel: channel["channel"]["id"],
          users: [first_user_id]
        )

        expect(response["ok"]).to be true

        # テスト後にチャンネルをアーカイブ
        vcr_client.conversations_archive(channel: channel["channel"]["id"])
      end
    end

    describe "#conversations_archive", vcr: { cassette_name: "slack/conversations_archive" } do
      it "チャンネルをアーカイブできる" do
        # VCRカセットに合わせた固定のチャンネル名を使用
        channel_name = "vcr-archive-test-1719288485"
        channel = vcr_client.conversations_create(name: channel_name)

        # チャンネルをアーカイブ
        response = vcr_client.conversations_archive(channel: channel["channel"]["id"])
        expect(response["ok"]).to be true
      end
    end
  end
end
