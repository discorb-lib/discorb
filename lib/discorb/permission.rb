# frozen_string_literal: true

require_relative 'flag'

module Discorb
  class Permission < Flag
    @bits = {
      create_instant_invite: 0,
      kick_members: 1,
      ban_members: 2,
      administrator: 3,
      manage_channels: 4,
      manage_guild: 5,
      add_reactions: 6,
      view_audit_log: 7,
      priority_speaker: 8,
      stream: 9,
      view_channel: 10,
      send_messages: 11,
      send_tts_messages: 12,
      manage_messages: 13,
      embed_links: 14,
      attach_files: 15,
      read_message_history: 16,
      mention_everyone: 17,
      use_external_emojis: 18,
      view_guild_insights: 19,
      connect: 20,
      speak: 21,
      mute_members: 22,
      deafen_members: 23,
      move_members: 24,
      use_vad: 25,
      change_nickname: 26,
      manage_nicknames: 27,
      manage_roles: 28,
      manage_webhooks: 29,
      manage_emojis: 30,
      use_slash_commands: 31,
      request_to_speak: 32,
      manage_threads: 34,
      use_public_threads: 35,
      use_private_threads: 36
    }
  end
end
