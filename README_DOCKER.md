# Reudy2025 Docker版

## 概要

このプロジェクトは、日本語人工無脳「Reudy」をDockerコンテナ化し、Ruby 3.4系で動作するようにアップグレードしたものです。

## 主な変更点

- **Dockerコンテナ化**: `docker exec`で実行可能
- **Ruby 3.4対応**: 最新のRubyで動作
- **MeCabデフォルト使用**: 形態素解析による高精度な単語抽出（`--no-mecab`で無効化可能）
- **Twitter代替**: Mastodon API対応を追加

## セットアップ

### 1. Dockerイメージのビルド

```bash
docker-compose build
```

または

```bash
docker build -t reudy2025 .
```

### 2. 設定ファイルの編集

`public/setting.yml`を編集して、使用するインターフェースの設定を行います。

#### IRCボットとして使用する場合

```yaml
:host: irc.ircnet.ne.jp
:port: 6668
:channel: "#reudy_test"
:encoding: UTF-8
```

#### Mastodonボットとして使用する場合

```yaml
:mastodon:
  :instance_url: "https://mastodon.example.com"
  :access_token: "your_access_token_here"
```

Mastodonのアクセストークンは、Mastodonインスタンスの「設定 > 開発 > アプリケーション」から取得できます。

### 3. 実行

#### docker-composeを使用する場合

```bash
# IRCボット
docker-compose run --rm reudy ruby irc_reudy.rb

# Mastodonボット
docker-compose run --rm reudy ruby mastodon_reudy.rb

# 標準入出力（対話型）
docker-compose run --rm reudy ruby stdio_reudy.rb
```

#### docker execを使用する場合

```bash
# コンテナを起動
docker-compose up -d

# IRCボットを実行
docker exec -it reudy ruby irc_reudy.rb

# Mastodonボットを実行
docker exec -it reudy ruby mastodon_reudy.rb

# 標準入出力（対話型）
docker exec -it reudy ruby stdio_reudy.rb
```

## コマンドラインオプション

- `-d DIRECTORY`: 設定ディレクトリを指定（デフォルト: `public`）
- `--db DB_TYPE`: 使用するDBMタイプを指定（デフォルト: `pstore`）
- `--no-mecab`: MeCabを使用しない（デフォルトではMeCabを使用）

**注意**: デフォルトでMeCabによる形態素解析を使用します。正規表現ベースの単語抽出を使用したい場合は`--no-mecab`オプションを指定してください。

例:

```bash
# MeCabを使用（デフォルト）
docker exec -it reudy ruby stdio_reudy.rb -d /app/public --db pstore

# MeCabを使用しない
docker exec -it reudy ruby stdio_reudy.rb --no-mecab
```

## データの永続化

`public/`ディレクトリと`data/`ディレクトリはボリュームとしてマウントされているため、データは永続化されます。

## トラブルシューティング

### Ruby 3.4での互換性

- `require 'thread'`を削除（標準ライブラリに統合済み）
- `File.exists?` → `File.exist?`に変更
- `File#lines` → `split`に変更（Ruby 3.4で削除されたメソッド）
- `Kernel.open` → `File.open`に変更
- `YAML.load` → `YAML.unsafe_load`に変更（Psych 5.0対応）

### MeCab

- DockerコンテナにはMeCab 0.996とmecab-ipadic-utf8辞書が組み込まれています
- MeCabの初期化に時間がかかる場合があります
- `--no-mecab`オプションでMeCabを無効化できます

### Mastodon API

- アクセストークンは「読み取り」と「書き込み」の権限が必要です
- API制限に達した場合、自動的に待機します

## ライセンス

元のReudyプロジェクトのライセンスに準拠します。

