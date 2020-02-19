# frozen_string_literal: true

require "sinatra"
require "sinatra/base"
require "sinatra/reloader"
require "pg"

class MemoApp < Sinatra::Base
  TITLE = "メモアプリ"
  PREFIX = "メモ"

  configure do
    enable :method_override
    register Sinatra::Reloader
  end

  before do
    @title = TITLE
    @add_btn = false
    @db_conn = PG.connect(dbname: "app")
  end

  helpers do
    def convert_to_zenkaku(memo_records)
      files = {}
      memo_records.each do |record|
        zenkaku_id = record["id"].tr("0-9", "０-９")  # 表示は全角
        files[record["id"]] = PREFIX + zenkaku_id
      end
      files
    end

    def fetch_content
      @db_conn.prepare("memo", "SELECT content FROM memos WHERE id = $1")
      record = @db_conn.exec_prepared("memo", [params[:id]])[0]
      content = record["content"]
      content.gsub!(/\n/, "<br>")
      content
    end
  end

  get "/" do
    @add_btn = true
    memo_records = @db_conn.exec("SELECT * FROM memos")
    @empty_notice = "メモがありません.追加してください" if memo_records.count < 1
    files = convert_to_zenkaku(memo_records)
    @files = files.sort.reverse.to_h  # keyでsort
    erb :index
  end

  get "/new" do
    erb :new
  end

  post "/" do
    @db_conn.prepare("memo", "INSERT INTO memos (content) VALUES ($1)")
    @db_conn.exec_prepared("memo", [params[:memo]])
    redirect "/"
  end

  get "/:id" do
    @content = fetch_content
    erb :show
  end

  get "/:id/edit" do
    @content = fetch_content
    erb :edit
  end

  patch "/:id" do
    @db_conn.prepare("memo", "UPDATE memos SET content = $1 WHERE id = $2")
    @db_conn.exec_prepared("memo", [params[:memo], params[:id]])
    redirect "/"
  end

  delete "/:id" do
    @db_conn.prepare("memo", "DELETE FROM memos WHERE id = $1")
    @db_conn.exec_prepared("memo", [params[:id]])
    redirect "/"
  end

  run! if app_file == $0
end
