#encoding: utf-8
#Copyright (C) 2025 Modified for Mastodon support

$REUDY_DIR= "./lib/reudy" unless defined?($REUDY_DIR)

Interval = 60 # タイムラインを取得する間隔
Abort_on_API_limit = false # API制限に引っかかった時にabortするかどうか

trap(:INT){ exit }

require 'optparse'
require 'net/http'
require 'json'
require 'time'
require $REUDY_DIR+'/bot_irc_client'
require $REUDY_DIR+'/reudy'
require $REUDY_DIR+'/reudy_common'

module Gimite
  class MastodonClient
    
    include(Gimite)
    
    def initialize(user)
      @user = user
      @user.client = self
      @last_toot = Time.now
      
      @instance_url = user.settings[:mastodon][:instance_url]
      @access_token = user.settings[:mastodon][:access_token]
      
      unless @instance_url && @access_token
        raise "Mastodon設定が不完全です。setting.ymlに:instance_urlと:access_tokenを設定してください。"
      end
      
      # URLの正規化（末尾のスラッシュを削除）
      @instance_url = @instance_url.chomp('/')
    end
    
    #補助情報を出力
    def outputInfo(s)
      puts "(#{s})"
    end
    
    #発言する（トゥートする）
    def speak(s)
      time = Time.now
      if time - @last_toot > Interval
        post_toot(s)
        puts "tooted: #{s}"
        @last_toot = time
      end
    end
    
    def onStatus(status)
      username = status['account']['username']
      content = extract_text_from_html(status['content'])
      @user.onOtherSpeak(username, content)
    end
    
    # HTMLからテキストを抽出（簡単な実装）
    def extract_text_from_html(html)
      # 基本的なHTMLタグを削除
      text = html.gsub(/<[^>]+>/, '')
      # HTMLエンティティをデコード
      text = text.gsub(/&lt;/, '<')
      text = text.gsub(/&gt;/, '>')
      text = text.gsub(/&amp;/, '&')
      text = text.gsub(/&quot;/, '"')
      text = text.gsub(/&#39;/, "'")
      text = text.gsub(/&nbsp;/, ' ')
      # 改行を正規化
      text = text.gsub(/\r\n|\r/, "\n")
      text.strip
    end
    
    # タイムラインを取得
    def fetch_timeline(since_id = nil)
      uri = URI("#{@instance_url}/api/v1/timelines/home")
      params = { limit: 20 }
      params[:since_id] = since_id if since_id
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@access_token}"
      
      response = http.request(request)
      
      if response.code == '200'
        JSON.parse(response.body)
      elsif response.code == '429'
        raise "Rate limit exceeded."
      else
        raise "API Error: #{response.code} #{response.message}"
      end
    end
    
    # トゥートを投稿
    def post_toot(text)
      uri = URI("#{@instance_url}/api/v1/statuses")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@access_token}"
      request['Content-Type'] = 'application/json'
      request.body = { status: text }.to_json
      
      response = http.request(request)
      
      unless response.code == '200'
        raise "Post failed: #{response.code} #{response.message}"
      end
      
      JSON.parse(response.body)
    end
  end
  
  opt = OptionParser.new
    
  directory = 'public'
  opt.on('-d DIRECTORY') do |v|
    directory = v
  end
  
  db = 'pstore'
  opt.on('--db DB_TYPE') do |v|
    db = v
  end
  
  mecab = nil
  opt.on('-m','--mecab') do |v|
    mecab = true
  end
  
  opt.parse!(ARGV)  
  
  # Mastodon用ロイディを作成
  client = MastodonClient.new(Reudy.new(directory,{},db,mecab))
    
  loop do
    begin
      since_id = nil
      statuses = client.fetch_timeline(since_id)
      
      statuses.reverse.each do |status|
        content = client.extract_text_from_html(status['content'])
        puts "#{status['account']['username']}: #{content}"
        since_id = status['id']
        client.onStatus(status)
      end
      
      sleep(Interval)
    rescue => ex
      case ex.message
      when /Rate limit exceeded/
        if Abort_on_API_limit
          abort ex.message
        else
          puts ex.message
          puts "API制限が解除されるまで待機します..."
          sleep(900) # 15分待機
        end
      else
        puts "Error: #{ex.message}"
        puts ex.backtrace.first(3).join("\n") if $DEBUG
        sleep(60) # エラー時は1分待機
      end
    end
  end
end

