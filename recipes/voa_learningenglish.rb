require 'kindlecook'
require 'date'

class VOALearningEnglish < KindleCook
  def initialize()
    argv = ARGV.select { |arg| not arg.start_with?("-") }
    if argv.empty?
      @end_date = nil
    else
      @end_date = Date.parse(argv[0])
      $stdout.puts "End date: #{@end_date}"
    end
  end

  def root_url
    "https://learningenglish.voanews.com"
  end

  def interval
    2
  end

  def prepare
    sections = []
    section = nil
    last_date = nil

    # 4693: Level One
    stop = false
    (0..4).each do |page|
      html = fetch_html("#{root_url}/z/4693?p=#{page}")
      @title = html.at_css(".pg-title").text() if page == 0
      html.css(".content-body .content").each do |div|
        date = Date.parse(div.at_css(".date").text())
        if (not @end_date.nil?) and @end_date > date
          stop = true
          break
        end
        if last_date.nil? || last_date != date
          sections.push(section) unless section.nil?
          section = {:title => date.to_s, :articles => []}
          last_date = date
        end
        a = div.at_css("a")
        file_name = a["href"].split("/").last
        save_article(file_name) do |f|
          article = fetch_html(a["href"])
          f.write(article.at_css(".pg-title"))
          post = article.at_css(".content-offset")
          post.search(".embed-player-only").remove  # remove mp3 player
          post.search("#comments").remove # remove comments
          f.write(post)
        end
        section[:articles].push({:title => a.at_css(".title").text(), :file => file_name})
      end
      break if stop
    end

    sections.push(section) unless section.nil?
    # 旧在前, 新在后
    sections.reverse
  end

  def document
    {
      "title" => "VOA Learning English - #{@title}",
      "author" => "VOA Learning English",
    }
  end
end

VOALearningEnglish.cook
