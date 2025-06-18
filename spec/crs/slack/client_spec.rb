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

  describe '#conversations_invite' do
    it "チャンネルにユーザーを招待できる（モック）" do
      allow(client).to receive(:post).and_return({ "ok" => true })
      res = client.conversations_invite(channel: "C12345", users: ["U1", "U2"])
      expect(res["ok"]).to be true
    end
    it "APIエラー時は例外を投げる" do
      allow(client).to receive(:post).and_return({ "ok" => false, "error" => "channel_not_found" })
      expect do
        client.conversations_invite(channel: "C12345", users: ["U1", "U2"])
      end.to raise_error(Crs::Slack::Client::SlackApiError, /Error inviting users/)
    end
  end

  describe '#conversations_archive' do
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
end
