require 'fileutils'
require 'open-uri'
require 'json'
require 'yaml'

require 'nokogiri'
require 'kindlerb'

class KindleCook

  # save articles & return sections.yml
  def prepare
    raise NotImplementedError
  end

  # hanlde relative path
  def root_url
    raise NotImplementedError
  end

  def slug
    self.class
  end

  def document
    {}
  end

  def workspace
    @workspace ||= "src/#{slug}"
  end

  def self.cook(format = "mobi")
    new.cook(format)
  end
  def cook(format)
    if ARGV.include?('-c')
      FileUtils.rm_rf(workspace)
    else
      FileUtils.rm_rf("#{workspace}/sections")
    end

    FileUtils.mkdir_p("#{workspace}/articles")
    FileUtils.mkdir_p("#{workspace}/images")
    FileUtils.mkdir_p("#{workspace}/sections")

    FileUtils.chdir(workspace) do
      File.open("sections.yml", "w") do |f|
        f.write prepare.to_yaml
      end

      build_document(format)
      build_sections
      Kindlerb.run(".")
    end
  end

  def build_document(format)
    File.open("_document.yml", "w") do |f|
      date = Date.today.to_s
      f.write({
        "doc_uuid" => slug,
        "title" => slug,
        "author" => slug,
        "publisher" => "SaulLawliet/kindlecook",
        "date" => date,
        "mobi_outfile" => "#{slug}_#{date}.#{format}",
        "masthead" => nil,
        "subject" => nil,
        "cover" => nil
      }.merge(document).to_yaml)
    end
  end

  def build_sections
    sections = YAML::load_file "sections.yml"
    sections.select! { |s| !s[:articles].empty? }
    raise "Sections can't be empty!" if sections.empty?

    sections.each_with_index do |section, section_index|
      dir = "sections/%03d" % section_index
      FileUtils.mkdir_p("#{dir}")
      File.open("#{dir}/_section.txt", 'w') { |f| f.write section[:title] }

      section[:articles].each_with_index do |article, article_index|
        html = Nokogiri::HTML """
<!DOCTYPE html>
<html lang=\"en\">
  <head>
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">
    <title>#{article[:title]}</title>
  </head>
  <body>
#{File.read("articles/#{article[:file]}")}
  </body>
</html>
        """

        html.css("img").each do |img|
          img["src"] = "#{FileUtils.pwd()}/#{save_image(img["src"])}"
        end

        File.open("#{dir}/%03d.html" % article_index, 'w') { |f| f.write html}
      end
    end
  end

  # save
  def save_image(url)
    file_name = url.split("/").last
    file = "images/#{file_name}"
    file += ".jpg" if file.index(".").nil?
    if (not File.exist?(file)) || File.zero?(file)
      begin
        fetch_file(url, file)
        run_shell("convert #{file} -background white -flatten #{file}")
      rescue
        $stderr.puts "Error: #{url}"
      end
    end
    file
  end

  def save_article(file_name)
    name="articles/#{file_name}"
    if (not File.exist?(name)) || File.zero?(name)
      yield File.open(name, "w")
    end
  end

  # helper
  def run_shell(cmd)
    $stdout.puts cmd
    `#{cmd}`
  end

  def absolute_url(url)
    return url if url.start_with?("http://") || url.start_with?("https://")
    return "#{root_url}/#{url}" unless url.start_with?("/")

    uri = URI(root_url)
    return "#{uri.scheme}#{url}" if url.start_with?("//")
    return "#{uri.scheme}://#{uri.host}#{url}"
  end

  def interval
    0
  end

  @@UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"
  def fetch(url)
    sleep(interval)
    url = absolute_url(url)
    $stdout.puts "Downloading: #{url}"
    open(url, "User-Agent" => @@UA).read
  end

  def fetch_html(url, src_coding=nil)
    content = fetch(url)
    content = content.encode("utf-8", src_coding) unless src_coding.nil?
    Nokogiri::HTML content
  end

  def fetch_json(url)
    JSON.parse fetch(url)
  end

  def fetch_file(url, file)
    File.open(file, 'wb') { |f| f << fetch(url) }
  end

end
