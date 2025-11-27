.PHONY: build up down exec-irc exec-mastodon exec-stdio shell

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

exec-irc:
	docker exec -it reudy ruby irc_reudy.rb

exec-mastodon:
	docker exec -it reudy ruby mastodon_reudy.rb

exec-stdio:
	docker exec -it reudy ruby stdio_reudy.rb

shell:
	docker exec -it reudy /bin/bash

run-irc:
	docker-compose run --rm reudy ruby irc_reudy.rb

run-mastodon:
	docker-compose run --rm reudy ruby mastodon_reudy.rb

run-stdio:
	docker-compose run --rm reudy ruby stdio_reudy.rb

