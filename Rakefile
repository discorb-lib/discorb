# frozen_string_literal: true

require 'bundler/gem_tasks'
task default: %i[]

task :emoji_table do
  require_relative 'lib/discorb'

  res = {}
  Discorb::EmojiTable::DISCORD_TO_UNICODE.each do |discord, unicode|
    res[unicode] ||= []
    res[unicode] << discord
  end

  res_text = +''
  res.each do |unicode, discord|
    res_text << %(#{unicode.unpack('C*').pack('C*').inspect} => %w[#{discord.join(' ')}],\n)
  end

  table_script = File.read('lib/discorb/emoji_table.rb')

  table_script.gsub!(/(?<=UNICODE_TO_DISCORD = {\n)[\s\S]+(?=}\.freeze)/, res_text)

  File.open('lib/discorb/emoji_table.rb', 'w') do |f|
    f.print(table_script)
  end
  `rubocop -A lib/discorb/emoji_table.rb`
  puts 'Successfully made emoji_table.rb'
end
