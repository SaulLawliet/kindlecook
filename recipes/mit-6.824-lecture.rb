require 'kindlecook'

class MIT_6824_LECTURE < KindleCook
  def root_url
    "https://pdos.csail.mit.edu/6.824"
  end

  def prepare
    articles = []
    fetch_html("#{root_url}/schedule.html").css("br~ b+ a").each_with_index do |a, index|
      # ["l01", "txt"]
      names = a['href'].split("/").last.split(".")

      # 只处理 txt 文件
      if names.last != 'txt'
        articles.push(nil)
        next
      end

      title = "#{index+1} #{a.text()}"
      file = "#{names.first}.html"

      begin
        save_article(file) do |f|
          content = fetch(a["href"])
          {'<' => '&lt;', '>' => '&gt;'}.each do |k, v|
            rtn = content.gsub(k, v)
            content = rtn if rtn
          end
          f.write("<pre>#{content}</pre>")
        end
        articles.push({:title => title, :file => file})
      rescue
        # 跳过 404
        articles.push(nil)
      end
    end

    articles_to_sections(articles, 5)
  end

  def document
    {
      "title" => "6.824 - lectures",
      "author" => "MIT",
    }
  end
end

MIT_6824_LECTURE.cook
