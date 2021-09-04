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

def gputs(text)
  puts "\e[90m#{text}\e[m"
end

def sputs(text)
  puts "\e[92m#{text}\e[m"
end

task :emoji_table do
  require_relative "lib/discorb"

  gputs "Building emoji_table.rb"
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
  sputs "Successfully made emoji_table.rb"
end

task :format do
  Dir.glob("**/*.rb").each do |file|
    next if file.start_with?("vendor")

    gputs "Formatting #{file}"
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
  namespace :replace do
    require "fileutils"
    task :css do
      gputs "Replacing css"
      Dir.glob("template-replace/files/**/*.*")
        .map { |f| f.delete_prefix("template-replace/files") }.each do |file|
        FileUtils.cp("template-replace/files" + file, "doc/#{version}/#{file}")
      end
      sputs "Successfully replaced css"
    end
    task :html do
      require_relative "template-replace/scripts/sidebar.rb"
      require_relative "template-replace/scripts/version.rb"
      require_relative "template-replace/scripts/index.rb"
      require_relative "template-replace/scripts/yard_replace.rb"
      gputs "Resetting changes"
      Dir.glob("doc/#{version}/**/*.html") do |f|
        next if (m = f.match(/[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?/)) && m[0] != version

        content = File.read(f)
        content.gsub!(/<!--od-->[\s\S]*<!--eod-->/, "")
        File.write(f, content)
      end
      gputs "Adding version tab"
      %w[file_list class_list method_list].each do |f|
        replace_sidebar("doc/#{version}/#{f}.html")
      end

      gputs "Building version tab"
      build_version_sidebar("doc/#{version}")
      gputs "Replacing _index.html"
      replace_index("doc/#{version}", version)
      gputs "Replacing YARD credits"
      yard_replace("doc/#{version}", version)
      gputs "Successfully replaced htmls"
    end
    task :eol do
      gputs "Replacing CRLF with LF"
      Dir.glob("doc/**/*.*") do |file|
        content = ""
        File.open(file, "rb") do |f|
          content = f.read
        end
        content.gsub!("\r\n", "\n")
        File.open(file, "wb") do |f|
          f.print(content)
        end
      end
      sputs "Successfully replaced CRLF with LF"
    end
  end
  task :replace => %i[replace:css replace:html replace:eol]
  task :build_all do
    require "fileutils"
    gputs "Building all versions"
    FileUtils.cp_r("./template-replace/.", "./tmp-template-replace")
    tags = `git tag`.force_encoding("utf-8").split("\n")
    tags.each do |tag|
      sh "git checkout #{tag} -f"
      gputs "Building #{tag}"
      FileUtils.cp_r("./tmp-template-replace/.", "./template-replace")
      version = tag.delete_prefix("v")
      Rake::Task["document:yard"].execute
      Rake::Task["document:replace:html"].execute
      Rake::Task["document:replace:css"].execute
      Rake::Task["document:replace:eol"].execute
    end
    version = "."
    Rake::Task["document:yard"].execute
    Rake::Task["document:replace:html"].execute
    Rake::Task["document:replace:css"].execute
    Rake::Task["document:replace:eol"].execute
    sh "git switch main -f"
    sputs "Successfully built all versions"
  end
  task :push do
    gputs "Pushing documents"
    Dir.chdir("doc") do
      sh "git add ."
      sh "git commit -m \"Update: Update document\""
      sh "git push -f"
    end
    sputs "Successfully pushed documents"
  end
end

task :document => %i[document:yard document:override]
