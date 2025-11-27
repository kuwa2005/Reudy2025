#!/bin/bash

docker-compose down
docker-compose build
docker-compose up -d

# 実行（IRCボットの場合）
#docker exec -it reudy ruby irc_reudy.rb

# または Mastodonボット
#docker exec -it reudy ruby mastodon_reudy.rb

# または 対話型
docker exec -it reudy ruby stdio_reudy.rb
