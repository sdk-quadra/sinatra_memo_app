# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"

before do
  @title = "メモアプリ"
  @ext = ".txt"
  @memo_loc = "./public/memo/"
  @prefix = "メモ"
  @delimiter = "_"
  @disp_add = "off"
end

helpers do
  def dir
    dir_files = Dir.entries(@memo_loc)
    dir_files = dir_files.select { |f| f unless f[0].include?(".") }  # 不可視ファイル除外
  end

  def f_content(id)
    file = File.open(@memo_loc + id + @ext)
    content = file.read
  end
end

get "/" do
  @disp_add = "on"
  dir_files = dir
  @is_empty = "まだメモがありません.追加してください" if dir_files.empty?

  files = {}
  dir_files.map { |b|
    key = b.gsub(/#{@delimiter}(.*)/, "")
    fname = b.gsub!(/#{@ext}/, "")

    zenkaku_num = key.tr("0-9", "０-９")  # 表示のファイル名数字は全角
    disp_fname = @prefix + zenkaku_num.to_s
    files[fname] = disp_fname
  }

  @files = files.sort.reverse.to_h  # keyでsort

  erb :index
end

get "/new" do
  erb :new
end

post "/" do
  memo = params[:memo]
  dir_files = dir

  unless dir_files.empty?
    file_num = dir_files.map! { |b| b.gsub(/#{@delimiter}(.*)/, "").to_i }
    last_file_num = file_num.max + 1
  else
    last_file_num = 1
  end
  
  new_file_name = last_file_num.to_s + @delimiter + SecureRandom.uuid

  File.open(@memo_loc + new_file_name + @ext, "w") do |f|
    f.write(memo)
  end
  redirect "/"
end

get "/:id" do
  id = params[:id]
  @content = f_content(id)
  @content.gsub!(/\n/, "<br>")
  erb :show
end

get "/:id/edit" do
  id = params[:id]
  @content = f_content(id)
  erb :edit
end

patch "/:id" do
  id = params[:id]
  memo = params[:memo]
  File.open(@memo_loc + id + @ext, "w") do |f|
    f.flock(File::LOCK_EX)
    f.write(memo)
  end
  redirect "/"
end

delete "/:id" do
  id = params[:id]
  File.delete(@memo_loc + id + @ext)
  redirect "/"
end
