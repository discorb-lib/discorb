# frozen_string_literal: true

require "bundler/gem_tasks"
require_relative "lib/discorb/utils/colored_puts"
require "parallel_tests"
task default: %i[]

# @private
def current_version
  require_relative "lib/discorb/common"
  tag = `git tag --points-at HEAD`.force_encoding("utf-8").strip
  if tag.empty?
    "main"
  else
    Discorb::VERSION
  end
end

desc "Run spec with parallel_rspec"
task :spec do
  sh "parallel_rspec spec/*.spec.rb spec/**/*.spec.rb"
end

desc "Build emoji_table.rb"
task :emoji_table do
  require_relative "lib/discorb"

  iputs "Building emoji_table.rb"
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

desc "Format files"
task :format do
  Dir.glob("**/*.rb").each do |file|
    next if file.start_with?("vendor")

    iputs "Formatting #{file}"
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

desc "Generate document and replace"
namespace :document do
  version = current_version
  desc "Just generate document"
  task :yard do
    sh "bundle exec yardoc -o doc/#{version} --locale #{ENV.fetch("rake_locale", nil) or "en"}"
  end

  desc "Replace files"
  namespace :replace do
    require "fileutils"

    desc "Replace CSS"
    task :css do
      iputs "Replacing css"
      Dir.glob("template-replace/files/**/*.*")
         .map { |f| f.delete_prefix("template-replace/files") }.each do |file|
        FileUtils.cp("template-replace/files" + file, "doc/#{version}/#{file}")
      end
      sputs "Successfully replaced css"
    end

    desc "Replace HTML"
    task :html do
      require_relative "template-replace/scripts/sidebar"
      require_relative "template-replace/scripts/version"
      require_relative "template-replace/scripts/index"
      require_relative "template-replace/scripts/yard_replace"
      require_relative "template-replace/scripts/favicon"
      require_relative "template-replace/scripts/arrow"
      iputs "Resetting changes"
      Dir.glob("doc/#{version}/**/*.html") do |f|
        next if (m = f.match(/[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?/)) && m[0] != version

        content = File.read(f)
        content.gsub!(/<!--od-->[\s\S]*<!--eod-->/, "")
        File.write(f, content)
      end
      iputs "Adding version tab"
      %w[file_list class_list method_list].each do |f|
        replace_sidebar("doc/#{version}/#{f}.html")
      end

      iputs "Building version tab"
      build_version_sidebar("doc/#{version}", version)
      iputs "Replacing _index.html"
      replace_index("doc/#{version}", version)
      iputs "Replacing YARD credits"
      yard_replace("doc/#{version}", version)
      iputs "Adding favicon"
      add_favicon("doc/#{version}")
      iputs "Replacing arrow"
      replace_arrow("doc/#{version}")
      iputs "Successfully replaced htmls"
    end

    desc "Replace EOL"
    task :eol do
      iputs "Replacing CRLF with LF"
      Dir.glob("doc/**/*.*") do |file|
        next unless File.file?(file)
        next unless %w[html css js].include? file.split(".").last

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

    desc "change locale of current document"
    task :locale do
      next if ENV["rake_locale"].nil?

      require_relative "template-replace/scripts/locale_#{ENV.fetch("rake_locale", nil)}.rb"
      replace_locale("doc/main")
    end
  end
  task replace: %i[replace:css replace:html replace:eol]

  desc "Build all versions"
  task :build_all do
    require "fileutils"

    iputs "Building all versions"
    begin
      FileUtils.rm_rf("doc")
    rescue StandardError
      nil
    end
    FileUtils.cp_r("./template-replace/.", "./tmp-template-replace")
    Rake::Task["document:yard"].execute
    Rake::Task["document:replace:html"].execute
    Rake::Task["document:replace:css"].execute
    Rake::Task["document:replace:eol"].execute
    Rake::Task["document:replace:locale"].execute
    tags = `git tag`.force_encoding("utf-8").split("\n").sort_by { |t| t[1..].split(".").map(&:to_i) }
    tags.each do |tag|
      sh "git checkout #{tag} -f"
      iputs "Building #{tag}"
      FileUtils.cp_r("./tmp-template-replace/.", "./template-replace")
      version = tag.delete_prefix("v")
      Rake::Task["document:yard"].execute
      Rake::Task["document:replace:html"].execute
      Rake::Task["document:replace:css"].execute
      Rake::Task["document:replace:eol"].execute
      Rake::Task["document:replace:locale"].execute
      FileUtils.cp_r("./doc/.", "./tmp-doc")
      FileUtils.rm_rf("doc")
    end
    sh "git switch main -f"
    FileUtils.cp_r("./tmp-doc/.", "./doc")
    FileUtils.cp_r("./doc/#{tags.last.delete_prefix("v")}/.", "./doc")
    sputs "Successfully built all versions"
  rescue StandardError => e
    sh "git switch main -f"
    raise e
  end

  desc "Push to discorb-lib/discorb-lib.github.io"
  task :push do
    iputs "Pushing documents"
    Dir.chdir("doc") do
      sh "git init"
      sh "git remote add origin git@github.com:discorb-lib/discorb-lib.github.io"
      sh "git add ."
      sh "git commit -m \"Update: Update document\""
      sh "git push -f"
    end
    sputs "Successfully pushed documents"
  end

  namespace :locale do
    desc "Generate Japanese document"
    task :ja do
      require "crowdin-api"
      require "zip"
      crowdin = Crowdin::Client.new do |config|
        config.api_token = ENV.fetch("CROWDIN_PERSONAL_TOKEN", nil)
        config.project_id = ENV["CROWDIN_PROJECT_ID"].to_i
      end
      build = crowdin.build_project_translation["data"]["id"]
      crowdin.download_project_translations("./tmp.zip", build)

      Zip::File.open("tmp.zip") do |zip|
        zip.each do |entry|
          zip.extract(entry, entry.name) { true }
        end
      end
      ENV["rake_locale"] = "ja"
      Rake::Task["document:yard"].execute
      Rake::Task["document:replace"].execute
    end

    desc "Generate English document"
    task :en do
      Rake::Task["document"].execute("locale:en")
    end
  end
end

desc "Generate rbs file"
namespace :rbs do
  desc "Generate event signature"
  task :event do
    client_rbs = File.read("sig/discorb/client.rbs")
    extension_rbs = File.read("sig/discorb/extension.rbs")
    event_document = File.read("./docs/events.md")
    voice_event_document = File.read("./docs/voice_events.md")
    event_reference = event_document.split("## Event reference")[1]
    event_reference += voice_event_document.split("# Voice Events")[1]
    event_reference.gsub!(/^### (.*)$/, "")
    events = []
    event_reference.split("#### `")[1..].each do |event|
      header, content = event.split("`\n", 2)
      name = header.split("(")[0]
      description = content.split("| Parameter", 2)[0].strip
      parameters = if content.include?("| Parameter")
          content.scan(/\| `(.*?)` +\| (.*?) +\| (.*?) +\|/)
        else
          []
        end
      events << {
        name: name,
        description: description,
        parameters: parameters.map { |p| { name: p[0], type: p[1], description: p[2] } },
      }
    end
    event_sig = +""
    event_lock_sig = +""
    extension_sig = +""
    events.each do |event|
      args = []
      event[:parameters].each do |parameter|
        args << {
          name: parameter[:name],
          type: if parameter[:type].start_with?("?")
            parameter[:type][1..]
          else
            parameter[:type]
          end.tr("{}`", "").tr("<>", "[]").gsub(", ", " | ").then do |t|
            if event[:name] == "event_receive"
              case t
              when "Hash"
                next "Discorb::json"
              end
            end
            t
          end,
        }
      end
      sig = args.map { |a| "#{a[:type]} #{a[:name]}" }.join(", ")
      tuple_sig = args.map { |a| a[:type] }.join(", ")
      tuple_sig = "[" + tuple_sig + "]" if args.length > 1
      tuple_sig = "void" if args.length.zero?
      event_sig << <<~RBS
        | (:#{event[:name]} event_name, ?id: Symbol?, **untyped metadata) { (#{sig}) -> void } -> Discorb::EventHandler
      RBS
      event_lock_sig << <<~RBS
        | (:#{event[:name]} event, ?Numeric? timeout) { (#{sig}) -> boolish } -> Async::Task[#{tuple_sig}]
      RBS
      extension_sig << <<~RBS
        | (:#{event[:name]} event_name, ?id: Symbol?, **untyped metadata) { (#{sig}) -> void } -> void
      RBS
    end
    event_sig.sub!("| ", "  ").rstrip!
    event_lock_sig.sub!("| ", "  ").rstrip!
    extension_sig.sub!("| ", "  ").rstrip!
    res = client_rbs.gsub!(/\# marker: on\n(?:[\s\S]*?\n)?( +)\# endmarker: on\n/) do
      indent = Regexp.last_match(1)
      "# marker: on\n#{event_sig.gsub(/^/, "#{indent}      ")}\n#{indent}# endmarker: on\n"
    end
    raise "Failed to generate Client#on" unless res

    res = client_rbs.gsub!(/\# marker: once\n(?:[\s\S]*?\n)?( +)\# endmarker: once\n/) do
      indent = Regexp.last_match(1)
      "# marker: once\n#{event_sig.gsub(/^/, "#{indent}        ")}\n#{indent}# endmarker: once\n"
    end
    raise "Failed to generate Client#once" unless res

    res = client_rbs.gsub!(/\# marker: event_lock\n(?:[\s\S]*?\n)?( +)\# endmarker: event_lock\n/) do
      indent = Regexp.last_match(1)
      "# marker: event_lock\n#{event_lock_sig.gsub(/^/, "#{indent}       ")}\n#{indent}# endmarker: event_lock\n"
    end
    raise "Failed to generate Client#event_lock" unless res

    res = extension_rbs.gsub!(/\# marker: event\n(?:[\s\S]*?\n)?( +)\# endmarker: event\n/) do
      indent = Regexp.last_match(1)
      "# marker: event\n#{extension_sig.gsub(/^/, "#{indent}       ")}\n#{indent}# endmarker: event\n"
    end
    raise "Failed to generate Extension.event" unless res

    res = extension_rbs.gsub!(/\# marker: once_event\n(?:[\s\S]*?\n)?( +)\# endmarker: once_event\n/) do
      indent = Regexp.last_match(1)
      "# marker: once_event\n#{extension_sig.gsub(/^/, "#{indent}       ")}\n#{indent}# endmarker: once_event\n"
    end
    raise "Failed to generate Extension.once_event" unless res

    File.write("sig/discorb/client.rbs", client_rbs, mode: "wb")
    File.write("sig/discorb/extension.rbs", extension_rbs, mode: "wb")
  end

  desc "Generate rbs file using sord"
  task :sord do
    require "open3"
    # rubocop: disable Layout/LineLength
    type_errors = {
      "SORD_ERROR_SymbolSymbolSymbolNumeric" => "{ r: Numeric, g: Numeric, b: Numeric}",
      "SORD_ERROR_DiscorbRoleDiscorbMemberDiscorbPermissionOverwrite" => "Hash[Discorb::Role | Discorb::Member, Discorb::PermissionOverwrite]",
      "SORD_ERROR_DiscorbRoleDiscorbMemberPermissionOverwrite" => "Hash[Discorb::Role | Discorb::Member, Discorb::PermissionOverwrite]",
      "SORD_ERROR_f | SORD_ERROR_F | SORD_ERROR_d | SORD_ERROR_D | SORD_ERROR_t | SORD_ERROR_T | SORD_ERROR_R" => '"f" | "F" | "d" | "D" | "t" | "T" | "R"',
      "SORD_ERROR_dark | SORD_ERROR_light" => '"dark" | "light"',
      "SORD_ERROR_SymbolStringSymbolboolSymbolObject" => "String | Numeric | Float",
    }
    # rubocop: enable Layout/LineLength
    regenerate = ARGV.include?("--regenerate") || ARGV.include?("-r")

    sh "sord gen sig/discorb.rbs --keep-original-comments --no-sord-comments" +
       (regenerate ? " --regenerate" : " --no-regenerate")
    base = File.read("sig/discorb.rbs")
    base.gsub!(/\n +def _set_data: \(.+\) -> untyped\n\n/, "\n")
    # base.gsub!(/(  )?( *)# @private.+?(?:\n\n(?=\1\2#)|(?=\n\2end))/sm, "")
    base.gsub!(/untyped ([a-z_]*id)/, "_ToS \\1")
    # #region rbs dictionary
    base.gsub!(/  class Dictionary.+?end\n/ms, <<-RBS)
    class Dictionary[K, V]
      #
      # Initialize a new Dictionary.
      #
      # @param [Hash] hash A hash of items to add to the dictionary.
      # @param [Numeric] limit The maximum number of items in the dictionary.
      # @param [false, Proc] sort Whether to sort the items in the dictionary.
      def initialize: (?::Hash[untyped, untyped] hash, ?limit: Numeric?, ?sort: (bool | Proc)) -> void

      #
      # Registers a new item in the dictionary.
      #
      # @param [#to_s] id The ID of the item.
      # @param [Object] body The item to register.
      #
      # @return [self] The dictionary.
      def register: (_ToS id, Object body) -> self

      #
      # Merges another dictionary into this one.
      #
      # @param [Discorb::Dictionary] other The dictionary to merge.
      def merge: (Discorb::Dictionary other) -> untyped

      #
      # Removes an item from the dictionary.
      #
      # @param [#to_s] id The ID of the item to remove.
      def remove: (_ToS id) -> untyped

      #
      # Get an item from the dictionary.
      #
      # @param [#to_s] id The ID of the item.
      # @return [Object] The item.
      # @return [nil] if the item was not found.
      #
      # @overload get(index)
      #   @param [Numeric] index The index of the item.
      #
      #   @return [Object] The item.
      #   @return [nil] if the item is not found.
      def get: (K id) -> V?

      #
      # Returns the values of the dictionary.
      #
      # @return [Array] The values of the dictionary.
      def values: () -> ::Array[V]

      #
      # Checks if the dictionary has an ID.
      #
      # @param [#to_s] id The ID to check.
      #
      # @return [Boolean] `true` if the dictionary has the ID, `false` otherwise.
      def has?: (_ToS id) -> bool

      #
      # Send a message to the array of values.
      def method_missing: (untyped name) -> untyped

      def respond_to_missing?: (untyped name, untyped args, untyped kwargs) -> bool

      def inspect: () -> String

      # @return [Numeric] The maximum number of items in the dictionary.
      attr_accessor limit: Numeric
    end
    RBS
    # #endregion
    type_errors.each do |error, type|
      base.gsub!(error, type)
    end
    base.gsub!("end\n\n\nend", "end\n")
    base.gsub!(/ +$/m, "")
    File.write("sig/discorb.rbs", base)
  end
end

task document: %i[document:yard document:replace]

desc "Lint code with rubocop"
task :lint do
  sh "rubocop lib spec Rakefile"
end

desc "Autofix code with rubocop"
task "lint:fix" do
  sh "rubocop lib spec Rakefile -A"
end
