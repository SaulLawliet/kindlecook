require 'kindlecook'

class SICP < KindleCook
  def root_url
    "https://mitpress.mit.edu/sicp/full-text/book"
  end

  def prepare
    sections = []
    section = nil
    html = fetch_html("book-Z-H-4.html")
    html.css("a").each do |a|
      next unless a["name"].to_s.include?("%_toc_%")

      if a.text().match(/^\d\.\d/).nil?
        sections.push(section) unless section.nil?
        section = {:title => a.text(), :articles => []}
      end

      # skip Level 3
      next unless a.text().match(/^\d\.\d\.\d/).nil?

      file_name = a["href"].split("#").first
      save_article(file_name) do |f|
        artical = fetch_html(file_name)
        artical.search(".navigation").remove
        f.write(artical.at("body"))
      end
      section[:articles].push({:title => a.text(), :file => file_name})
    end
    sections.push(section) unless section.nil?
    sections
  end

  def document
    {
      "title" => "Structure and Interpretation of Computer Programs",
      "author" => "Harold Abelson, Gerald Jay Sussman, Julie Sussman",
      "cover" => save_image("cover.jpg"),
    }
  end

end

SICP.cook("azw3")
