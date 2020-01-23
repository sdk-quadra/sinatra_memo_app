# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"

class Rack::MethodOverride
  ALLOWED_METHODS=%w[POST GET]
  def method_override(env)
    req = Rack::Request.new(env)
    method = req.params[METHOD_OVERRIDE_PARAM_KEY] || env[HTTP_METHOD_OVERRIDE_HEADER]
    method.to_s.upcase
  end
end
enable :method_override

before do
  @title = "メモアプリ"
  @ext = ".txt"
  @memo_loc = "./public/memo/"
  @disp_add = "off"
end

helpers do
  def dir
    dir_files = Dir.entries(@memo_loc)
    dir_files = dir_files.select { |f| f unless f[0].include?(".") }  # 不可視ファイル除外
  end

  def f_content(file_num)
    file = File.open(@memo_loc + file_num)
    content = file.read
  end
end

get "/"  do
  @disp_add = "on"
  dir_files = dir
  @is_empty = "まだメモはありません" if dir_files.empty?

  files = Hash.new
  dir_files.map { |b|
    b.gsub!(/#{@ext}/, "")
    zenkaku_num = b.tr("0-9", "０-９")  # 表示のファイル名数字は全角
    disp_fname = "メモ" + zenkaku_num.to_s
    files[b] = disp_fname
  }
  @files = files.sort_by { |_, v| v }.to_h  # valでsort

  erb :index
end

get "/new" do
  erb :new
end

post "/create" do
  memo = params[:memo]

  memo.gsub!(/[\p{Z}\t\r\n\v\f]/, "")
  if memo.size < 1  # 空文字は保存しない
    redirect "/new"
  end

  dir_files = dir
  file_num = dir_files.map! { |b| b.gsub(/#{@ext}/, "").to_i }
  last_file_num = file_num.max + 1

  File.open(@memo_loc + last_file_num.to_s + @ext, "w") do |f|
    f.write(memo)
  end
  redirect "/"
end

get "/:file_num" do
  file_num = params[:file_num]
  @content = f_content(file_num + @ext)
  @content.gsub!(/\n/, "<br>")
  erb :show
end

get "/:file_num/edit" do
  file_num = params[:file_num]
  @content = f_content(file_num + @ext)
  erb :edit
end

patch "/:file_num/update" do
  file_num = params[:file_num]
  memo = params[:memo]
  File.open(@memo_loc + file_num + @ext, "w") do |f|
    f.write(memo)
  end
  redirect "/"
end

delete "/:file_num/delete" do
  file_num = params[:file_num]
  File.delete(@memo_loc + file_num + @ext)
  redirect "/"
end
