# frozen_string_literal: true

# require "discorb"
require_relative "../lib/discorb"

client = Discorb::Client.new(log: $stdout, colorize_log: true, log_level: :info)

def get_log_channel(guild)
  guild.channels.find { |c| c.name == "log" }
end

client.on :ready do
  puts "Logged in as #{client.user}"
end
# ==== Channels ====
client.on :channel_create do |_task, channel|
  get_log_channel(channel.guild).post embed: Discorb::Embed.new(
    "Channel Created", "Name: `#{channel.name}`\n\n#{channel}", color: Discorb::Color[:green], timestamp: Time.now,
  )
end

client.on :channel_update do |_task, before, after|
  next if before.name == after.name

  get_log_channel(after.guild).post embed: Discorb::Embed.new(
    "Channel Renamed", "`#{before.name}` -> `#{after.name}`", color: Discorb::Color[:yellow], timestamp: Time.now,
  )
end

client.on :channel_delete do |_task, channel|
  get_log_channel(channel.guild).post embed: Discorb::Embed.new(
    "Channel Deleted", "`#{channel.name}`", color: Discorb::Color[:red], timestamp: Time.now,
  )
end
# ===== Roles =====
client.on :role_create do |_task, role|
  get_log_channel(role.guild).post embed: Discorb::Embed.new(
    "Role Created", "Name: `#{role.name}`\n\n#{role}", color: Discorb::Color[:green], timestamp: Time.now,
  )
end

client.on :role_update do |_task, before, after|
  next if before.name == after.name

  get_log_channel(after.guild).post embed: Discorb::Embed.new(
    "Role Renamed", "`#{before.name}` -> `#{after.name}`", color: Discorb::Color[:yellow], timestamp: Time.now,
  )
end

client.on :role_delete do |_task, role|
  get_log_channel(role.guild).post embed: Discorb::Embed.new(
    "Role Deleted", "`#{role.name}`", color: Discorb::Color[:red], timestamp: Time.now,
  )
end

client.on :voice_channel_connect do |_task, state|
  get_log_channel(state.guild).post embed: Discorb::Embed.new(
    "Connected to VC", "User: #{state.member.mention}\nChannel: #{state.channel.mention}", color: Discorb::Color[:green],
  )
end

client.on :voice_channel_move do |_task, before, after|
  get_log_channel(before.guild).post embed: Discorb::Embed.new(
    "Moved to other VC", "User: #{before.member.mention}\nChannel: #{before.channel.mention} -> #{after.channel.mention}", color: Discorb::Color[:yellow],
  )
end

client.on :voice_channel_disconnect do |_task, state|
  get_log_channel(state.guild).post embed: Discorb::Embed.new(
    "Disconnected from VC", "User: #{state.member.mention}\nChannel: #{state.channel.mention}", color: Discorb::Color[:red],
  )
end
client.run(ENV["discord_bot_token"])
