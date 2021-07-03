# frozen_string_literal: true

require 'time'
require_relative 'user'

module Discorb
  class Member < User
    attr_reader :roles, :premium_since, :nick, :joined_at, :hoisted_role, :custom_avatar

    def initialize(client, guild_id, user_data, member_data)
      @guild_id = guild_id
      super(client, user_data)

      _set_data(user_data, member_data)
    end

    def guild
      @client.guilds[@guild_id]
    end

    def roles
      @role_ids.map { |r| guild.roles[r] }
    end

    def hoisted_role
      @hoisted_role_id ? guild.roles[@hoisted_role_id] : nil
    end

    def hoisted?
      !@hoisted_role_id.nil?
    end

    def user_avatar
      @avatar
    end

    def avatar
      @display_avatar
    end

    def mute?
      @mute
    end

    def deaf?
      @deaf
    end

    def pending?
      @pending
    end

    private

    def _set_data(user_data, member_data = nil)
      return if member_data.nil?

      @role_ids = member_data[:roles]
      @premium_since = member_data[:premium_since] ? Time.iso8601(member_data[:premium_since]) : nil
      @pending = member_data[:pending]
      @nick = member_data[:nick]
      @mute = member_data[:mute]
      @joined_at = member_data[:joined_at] ? Time.iso8601(member_data[:joined_at]) : nil
      @hoisted_role_id = member_data[:hoisted_role]
      @deaf = member_data[:deaf]
      @custom_avatar = member_data[:avatar]
      @display_avatar = Avatar.new(self, member_data[:avatar] || user_data[:avatar])
      super(user_data)
    end

    #:roles=>["858521005340622849"], :premium_since=>nil, :pending=>false, :nick=>nil, :mute=>false, :joined_at=>"2021-06-27T01:35:58.256425+00:00", :is_pending=>false, :hoisted_role=>nil, :deaf=>false, :avatar=>nil
  end
end
