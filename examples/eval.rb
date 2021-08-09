# frozen_string_literal: true

require_relative '../lib/discorb'

client = Discorb::Client.new(
  log: $stdout, colorize_log: true, log_level: :info,
  wait_until_ready: true, intents: Discorb::Intents.all
)

client.on(:ready) do |_task|
  puts "Logged in as #{client.user}"
end

event = client.on(:message) do |_task, message|
  next if message.author.bot?
  next unless message.content.start_with?('eval ')

  unless message.author.bot_owner?.wait
    message.reply("You don't have permission to use this command.")
    next
  end

  code = message.content.delete_prefix('eval ').delete_prefix('```rb').delete_suffix('```')
  res = eval("Async { |task| #{code} }", binding, __FILE__, __LINE__).wait  # rubocop:disable Security/Eval
  message.add_reaction(Discorb::UnicodeEmoji['white_check_mark'])
  unless res.nil?
    res = res.wait if res.is_a? Async::Task
    message.channel.post("```rb\n#{res.inspect[...1990]}\n```")
  end
end

event.rescue do |_task, error, message|
  message.reply embed: Discorb::Embed.new('Error!', "```rb\n#{error.full_message(highlight: false)[...1990]}\n```",
                                          color: Discorb::Color[:red])
end

client.run(ENV['discord_bot_token'])
