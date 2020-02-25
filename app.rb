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
    @show_add_button = false
    @db_conn = PG.connect(dbname: "app")
  end

  helpers do
    def convert_to_zenkaku(id)
      id.tr("0-9", "０-９")
    end

    def find_content(id)
      @db_conn.prepare("memo", "SELECT content FROM memos WHERE id = $1")
      @db_conn.exec_prepared("memo", [id])[0]["content"]
    end

    def convert_nl_to_br(content)
      content.gsub(/\n/, "<br>")
    end

    def show_add_button?
      @show_add_button
    end
  end

  get "/" do
    @show_add_button = true
    @memo_records = @db_conn.exec("SELECT * FROM memos ORDER BY id DESC")
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
    @content = find_content(params[:id])    
    erb :show
  end

  get "/:id/edit" do
    @content = find_content(params[:id])
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
