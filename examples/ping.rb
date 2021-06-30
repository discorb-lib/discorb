# frozen_string_literal: true

# require "discorb"
require_relative '../lib/discorb'
require 'async'

client = Discorb::Client.new(log: $stdout, colorize_log: true, log_level: :info, allowed_mentions: Discorb::AllowedMentions.new(replied_user: false))

client.on :ready do |_task|
  puts "Logged in as #{client.user}"
end

client.on(:message) do |_task, message|
  if message.author.bot?
    next
  elsif !message.content.start_with? '!'
    next
  end

  case message.content[1..]
  when 'ping'
    message.channel.post 'Pong!'
  when 'emtest'
    msg = message.channel.post(embed: Discorb::Embed.new('Embed Test', 'I am test')).wait
  when /eval [\s\S+]/
    code = message.content.delete_prefix('!eval ').delete_prefix('```rb').delete_suffix('```')
    res = eval(code)
    message.add_reaction(Discorb::UnicodeEmoji['white_check_mark'])
    unless res.nil?
      res = res.wait if res.is_a? Async::Task
      message.channel.post("```rb\n#{res.inspect[...1990]}\n```")
    end
  when 'react'
    message.add_reaction(Discorb::UnicodeEmoji['white_check_mark'])
  when 'reply'
    message.reply 'Test'
  end
end.rescue do |_task, error, message|
  message.reply embed: Discorb::Embed.new('Error!', "```rb\n#{error.full_message(highlight: false)[...1990]}\n```", color: Discorb::Color[:red])
end

client.update_presence(Discorb::Activity.new('Music', :listening))
client.run(ENV['DISCORD_BOT_TOKEN'])
