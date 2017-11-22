# -*- coding: utf-8 -*-
require 'kindlecook'

class Zhihu < KindleCook
  def initialize()
    argv = ARGV.select { |arg| not arg.start_with?("-") }
    if argv.empty?
      $stderr.puts "You should specify an ID."
      raise RuntimeError
    end
    @id = argv[0]
  end

  def root_url
    # 只有图片是相对路径
    "http://pic1.zhimg.com"
  end

  def slug
    "#{self.class.to_s}_#{@id}"
  end

  def prepare
    posts = []
    i = 0
    while true do
      arr = fetch_json "https://zhuanlan.zhihu.com/api/columns/#{@id}/posts?limit=20&offset=#{i * 20}"
      posts.concat(arr)
      break if arr.length < 20
      i += 1
    end

    sections = []
    section = nil
    posts.reverse.each_with_index do |post, index|
      if index % 10 == 0
        sections.push(section) unless section.nil?
        section = {:title => "#{index+1}-#{index+10}", :articles => []}
      end
      title = post["title"]
      file = "#{post["slug"]}.html"

      save_article(file) do |f|
        f.write("<h1>#{title}</h1><br>")
        f.write(post["content"])
      end

      section[:articles].push({:title => title, :file => file})
    end

    sections.push(section) unless section.nil?
    sections
  end

  def document
    info = fetch_json "https://zhuanlan.zhihu.com/api/columns/#{@id}"

    {
      "title" => info["name"],
      "author" => info["creator"]["name"],
      "cover" => save_image(info["avatar"]["id"])
    }
  end

end

Zhihu.cook("mobi")
