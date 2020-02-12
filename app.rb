# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "pg"

before do
  @title = "メモアプリ"
  @prefix = "メモ"
  @disp_add = "off"

  @db_conn = PG.connect(dbname: "app")
  @table = "memos"
  @col_content = "content"
end

helpers do
  def transact(sql)
    @db_conn.exec("BEGIN")
    if @db_conn.exec(sql)
      @db_conn.exec("COMMIT")
    else
      @db_conn.exec("ROLLBACK")
    end
  end
end

get "/" do
  @disp_add = "on"
  files = {}

  memo_records = @db_conn.exec("SELECT * FROM #{@table}")
  @is_empty = "メモがありません.追加してください" if memo_records.count < 1

  memo_records.each do |record|
    zenkaku_id = record["id"].tr("0-9", "０-９")  # 表示は全角
    files[record["id"]] = @prefix + zenkaku_id
  end

  @files = files.sort.reverse.to_h  # keyでsort

  erb :index
end

get "/new" do
  erb :new
end

post "/" do
  memo = params[:memo]
  sql = "INSERT INTO #{@table} (#{@col_content}) values (E'#{memo}')"
  transact(sql)
  redirect "/"
end

get "/:id" do
  id = params[:id]
  content = @db_conn.exec("SELECT #{@col_content} FROM #{@table} WHERE id = #{id}")
  content.each do |c|
    @content = c["#{@col_content}"]
  end
  @content.gsub!(/\n/, "<br>")
  erb :show
end

get "/:id/edit" do
  id = params[:id]
  content = @db_conn.exec("SELECT #{@col_content} FROM #{@table} WHERE id = #{id}")
  content.each do |c|
    @content = c["#{@col_content}"]
  end
  erb :edit
end

patch "/:id" do
  id = params[:id]
  memo = params[:memo]
  sql = "UPDATE #{@table} SET #{@col_content} = E'#{memo}' WHERE id = #{id}"
  transact(sql)
  redirect "/"
end

delete "/:id" do
  id = params[:id]
  sql = "DELETE FROM #{@table} where id = #{id}"
  transact(sql)
  redirect "/"
end
