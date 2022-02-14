# frozen_string_literal: true
require "fileutils"

def replace_index(dir, version)
  Dir.glob("#{dir}/**/*.html").each do |file|
    next if (m = file.match(/[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?/)) && m[0] != version

    content = File.read(file)
    content.gsub!(%r{(?<=["/])_index.html}, "a_index.html")
    File.write(file, content)
  end

  FileUtils.cp("#{dir}/_index.html", "#{dir}/a_index.html")
end
