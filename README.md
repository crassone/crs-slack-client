[![Build and Commit Gem](https://github.com/crassone/crs-slack-client/actions/workflows/build-and-commit-gem.yml/badge.svg)](https://github.com/crassone/crs-slack-client/actions/workflows/build-and-commit-gem.yml)
[![Ruby](https://github.com/crassone/crs-slack-client/actions/workflows/main.yml/badge.svg)](https://github.com/crassone/crs-slack-client/actions/workflows/main.yml)

# Crs::Slack::Client

## Overview

このリポジトリは、Crassone 用の Slack API クライアント Gem「crs-slack-client」を開発・管理してるよ！

- Ruby で Slack API を簡単に叩けるクライアントを提供！
- チャンネルへのメッセージ送信、画像付きリプライ、ユーザー一覧取得などの機能があるよ
- Ruby 3.2 以上対応
- GitHub Actions で自動的に gem をビルドして、.gem ファイルもコミットされる仕組み！

Slack 連携をサクッとやりたい人向けの便利 Gem だよ ✨

## build

```bash
gem build crs-slack-client.gemspec

  Successfully built RubyGem
  Name: crs-slack-client
  Version: 0.1.0
  File: crs-slack-client-0.1.0.gem
```

## Usage

Gemfile

```ruby
gem 'crs-slack-client', git: 'git@github.com:crassone/crs-slack-client.git'
```

## 開発時の注意事項

- specを実行する場合は、環境変数 `SLACK_API_TOKEN` を予めセットしておいてください

```
export SLACK_API_TOKEN='xoxb-xxxxxx-xxxx-xxxxxx'
```


## サンプルコード

```ruby
require 'crs/slack/client'

token = 'xoxb-xxxxxx-xxxx-xxxxxx'
slack_client = Crs::Slack::Client.new(
  api_token: token,
)

pp slack_client.users_list

slack_channel_id = 'xxxxxxxx'

slack_post_response = slack_client.chat_post_message(
  channel: slack_channel_id,
  text: "Hello from crs-slack-client! :wave: \nhttps://github.com/crassone/crs-slack-client",
)

image_urls = [
  Crs::Slack::Client::ImageUrl.new(
    url: 'https://image.lgtmoon.dev/517710',
    alt_text: '517710'
  )
]

pp slack_client.add_reply(
  channel: slack_channel_id,
  thread_ts: slack_post_response['ts'],
  image_urls: image_urls
)
```

=>
https://crassone-go-boldly.slack.com/archives/C08TH1GJPUZ/p1747900032620499
