LOCALES = {
  "ja" => {
    selector: {
      "Classes" => "クラス",
      "Methods" => "メソッド",
      "Files" => "ファイル",
      "Versions" => "バージョン",
    },
    title: {
      "Class List" => "クラス一覧",
      "Method List" => "メソッド一覧",
      "File List" => "ファイル一覧",
      "Version List" => "バージョン一覧",
    },
  },

}

def replace_sidebar_name(dir)
  regex = /<a target="_self" href="(.+)_list\.html">\s*([a-zA-Z ]+?)\s*<\/a>/

  Dir.glob("#{dir}/*_list.html") do |file|
    content = File.read(file)
    new_content = content.dup
    content.scan(regex) do |url, name|
      new_content.gsub!(
        Regexp.last_match[0],
        Regexp.last_match[0].gsub(name, LOCALES[ENV["rake_locale"]][:selector][name])
      )
    end
    File.write(file, new_content)
  end
end

def replace_title(dir)
  regex = /(?:<h1 id="full_list_header">|<title>)([a-zA-Z ]+?)(?:<\/title>|<\/h1>)/

  Dir.glob("#{dir}/*.html") do |file|
    content = File.read(file)
    new_content = content.dup
    content.scan(regex) do |title, _|
      new_content.gsub!(
        Regexp.last_match[0],
        Regexp.last_match[0].gsub(title, LOCALES[ENV["rake_locale"]][:title][title])
      )
    end
    File.write(file, new_content)
  end
end

def replace_version_name(dir)
  content = File.read("#{dir}/version_list.html")
  content.gsub!("Latest on RubyGems", "RubyGemsでの最新版")
  content.gsub!("Latest on GitHub", "GitHubでの最新版")
  File.write("#{dir}/version_list.html", content)
end

def replace_locale(dir)
  replace_sidebar_name(dir)
  replace_version_name(dir)
  replace_title(dir)
end
