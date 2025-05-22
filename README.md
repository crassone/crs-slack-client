# Crs::Slack::Client

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

```ruby
require 'crs/slack/client'

token = 'xoxb-xxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxx'
slack_client = Crs::Slack::Client.new(
  api_token: token,
)

pp slack_client.users_list
pp slack_client.chat_post_message(
  channel: 'C08TH1GJPUZ',
  text: "Hello from crs-slack-client! :wave: \nhttps://github.com/crassone/crs-slack-client",
)
```
