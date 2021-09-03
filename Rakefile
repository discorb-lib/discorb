# frozen_string_literal: true

require "bundler/gem_tasks"
task default: %i[]

def get_version
  require_relative "lib/discorb/common"
  latest_commit = `git log --oneline`.force_encoding("utf-8").split("\n")[0]
  version = Discorb::VERSION
  unless latest_commit.downcase.include?("update version")
    version += "-dev"
  end
  version
end

task :emoji_table do
  require_relative "lib/discorb"

  res = {}
  Discorb::EmojiTable::DISCORD_TO_UNICODE.each do |discord, unicode|
    res[unicode] ||= []
    res[unicode] << discord
  end

  res_text = +""
  res.each do |unicode, discord|
    res_text << %(#{unicode.unpack("C*").pack("C*").inspect} => %w[#{discord.join(" ")}],\n)
  end

  table_script = File.read("lib/discorb/emoji_table.rb")

  table_script.gsub!(/(?<=UNICODE_TO_DISCORD = {\n)[\s\S]+(?=}\.freeze)/, res_text)

  File.open("lib/discorb/emoji_table.rb", "w") do |f|
    f.print(table_script)
  end
  `rufo lib/discorb/emoji_table.rb`
  puts "Successfully made emoji_table.rb"
end

task :format do
  Dir.glob("**/*.rb").each do |file|
    next if file.start_with?("vendor")

    puts "Formatting #{file}"
    `rufo ./#{file}`
    content = ""
    File.open(file, "rb") do |f|
      content = f.read
    end
    content.gsub!("\r\n", "\n")
    File.open(file, "wb") do |f|
      f.print(content)
    end
  end
end
namespace :document do
  version = get_version
  task :yard do
    sh "yardoc -o doc/#{version}"
  end
  namespace :override do
    require "fileutils"
    task :css do
      Dir.glob("template-overrides/files/**/*.*")
        .map { |f| f.delete_prefix("template-overrides/files") }.each do |file|
        FileUtils.cp("template-overrides/files" + file, "doc/#{version}/#{file}")
      end
    end
    task :html do
      require_relative "template-overrides/scripts/sidebar.rb"
      require_relative "template-overrides/scripts/version.rb"
      Dir.glob("doc/#{version}/**/*.html") do |f|
        content = File.read(f)
        content.gsub!(/<!--od-->[\s\S]*<!--eod-->/, "")
        File.write(f, content)
      end
      %w[file_list class_list method_list].each do |f|
        replace_sidebar("doc/#{version}/#{f}.html")
      end

      build_version_sidebar("doc/#{version}")
    end
  end
  task :build_all do
    gitignore = File.read(".gitignore")
    File.write(".gitignore", gitignore + "\ntemplate-overrides")
    sh "git commit -am tmp"
    tags = `git tag`
    tags.split("\n").each do |tag|
      sh "git checkout #{tag}"
      version = tag.delete_prefix("v")
      Rake::Task["document:yard"].execute
      Rake::Task["document:override:css"].execute
      Rake::Task["document:override:html"].execute
    end
    version = "."
    Rake::Task["document:yard"].execute
    Rake::Task["document:override:css"].execute
    Rake::Task["document:override:html"].execute
    sh "git switch main"
  end
  task :override => %i[override:css override:html]
end

task :document => %i[document:yard document:override]
