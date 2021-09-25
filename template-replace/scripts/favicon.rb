require "fileutils"

def add_favicon(dir)
  Dir.glob("#{dir}/**/*.html").each do |file|
    content = File.read(file)
    content.gsub!(/<head>/, "<head>\n<link rel=\"shortcut icon\" href=\"favicon.png\" />")
    File.write(file, content)
  end
end
