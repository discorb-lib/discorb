# frozen_string_literal: true

# require "discorb"
require 'time'
require_relative '../lib/discorb'

client = Discorb::Client.new(log: $stdout, colorize_log: true)

def get_log_channel(guild)
  guild.channels.find { |c| c.name == 'log' }
end

client.on :ready do
  puts "Logged in as #{client.user}"
end

client.on :channel_create do |_task, channel|
  get_log_channel(channel.guild).post embed: Discorb::Embed.new(
    'Channel Created', "Name: `#{channel.name}`\n\n#{channel}", color: Discorb::Color[:green], timestamp: Time.now
  )
end

client.on :channel_update do |_task, before, after|
  next if before.name == after.name

  get_log_channel(after.guild).post embed: Discorb::Embed.new(
    'Channel Renamed', "`#{before.name}` -> `#{after.name}`", color: Discorb::Color[:yellow], timestamp: Time.now
  )
end

client.on :channel_delete do |_task, channel|
  get_log_channel(channel.guild).post embed: Discorb::Embed.new(
    'Channel Deleted', "`#{channel.name}`", color: Discorb::Color[:red], timestamp: Time.now
  )
end

client.on :role_create do |_task, role|
  get_log_channel(role.guild).post embed: Discorb::Embed.new(
    'Role Created', "Name: `#{role.name}`\n\n#{role}", color: Discorb::Color[:green], timestamp: Time.now
  )
end

client.on :role_update do |_task, before, after|
  next if before.name == after.name

  get_log_channel(after.guild).post embed: Discorb::Embed.new(
    'Role Renamed', "`#{before.name}` -> `#{after.name}`", color: Discorb::Color[:yellow], timestamp: Time.now
  )
end

client.on :role_delete do |_task, role|
  get_log_channel(role.guild).post embed: Discorb::Embed.new(
    'Role Deleted', "`#{role.name}`", color: Discorb::Color[:red], timestamp: Time.now
  )
end

client.run(ENV['discord_bot_token'])
