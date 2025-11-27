#Copyright (C) 2003 Gimite 市川 <gimite@mx12.freecom.ne.jp>
#Modified by Glass_saga <glass.saga@gmail.com>

require $REUDY_DIR+'/reudy_common'
require "psych" #UTF-8をバイナリで書き出さないようにする
require "yaml"

module Gimite
  #個々の発言
  class Message
    def initialize(from_nick, body)
      @fromNick = from_nick
      @body = body
    end
  
    attr_accessor :fromNick,:body
  end
  
  #発言ログ
  class MessageLog
    include Gimite
    
    def initialize(inner_filename)
      @innerFileName = inner_filename
      @observers = []
      File.open(inner_filename) do |f|
        content = f.read
        # YAMLファイルは---で区切られているので、---で分割
        parts = content.split(/^---$/).reject(&:empty?)
        @size = parts.count
      end
    end
  
    attr_accessor :size
    
    #観察者を追加。
    def addObserver(*observers)
      @observers.concat(observers)
    end
  
    #n番目の発言
    def [](n)
      n += @size if n < 0 #末尾からのインデックス
      return nil if n < 0 || n >= @size
      File.open(@innerFileName) do |f|
        content = f.read
        parts = content.split(/^---$/).reject(&:empty?)
        line = parts[n]
        if line && !line.strip.empty?
          m = YAML.unsafe_load("---\n#{line}")
          return Message.new(m[:fromNick], m[:body])
        else
          return nil
        end
      end
    end
    
    #発言を追加
    def addMsg(from_nick, body, to_outer = true)
      File.open(@innerFileName, "a") do |f|
        YAML.dump({:fromNick => from_nick, :body => body}, f)
      end
      @size += 1
      @observers.each(&:onAddMsg)
    end
   
    private
    
    #内部データをクリア(デフォルトのログのみ残す)
    def clear
      File.open(@innerFileName, "r+") do |f|
        content = f.read
        parts = content.split(/^---$/).reject(&:empty?)
        default = parts.select{|s| !s.strip.empty? && YAML.unsafe_load("---\n#{s}")[:fromNick] == "Default" }
        f.rewind
        f.truncate(0)
        default.each_with_index { |line, idx| f.write("#{idx > 0 ? "---\n" : ""}#{line}") }
        @size = default.size
      end
    end
  end
end
