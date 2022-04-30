# frozen_string_literal: true

module Discorb
  #
  # Represents a allowed mentions in a message.
  #
  class AllowedMentions
    # @return [Boolean] Whether to allow @everyone or @here.
    attr_accessor :everyone
    # @return [Boolean, Array<Discorb::Role>] The roles to allow, or false to disable.
    attr_accessor :roles
    # @return [Boolean, Array<Discorb::User>] The users to allow, or false to disable.
    attr_accessor :users
    # @return [Boolean] Whether to ping the user that sent the message to reply.
    attr_accessor :replied_user

    #
    # Initializes a new instance of the AllowedMentions class.
    #
    # @param [Boolean] everyone Whether to allow @everyone or @here.
    # @param [Boolean, Array<Discorb::Role>] roles The roles to allow, or false to disable.
    # @param [Boolean, Array<Discorb::User>] users The users to allow, or false to disable.
    # @param [Boolean] replied_user Whether to ping the user that sent the message to reply.
    #
    def initialize(everyone: nil, roles: nil, users: nil, replied_user: nil)
      @everyone = everyone
      @roles = roles
      @users = users
      @replied_user = replied_user
    end

    def inspect
      "#<#{self.class} @everyone=#{@everyone} @roles=#{@roles} @users=#{@users} @replied_user=#{@replied_user}>"
    end

    #
    # Converts the object to a hash.
    # @private
    #
    # @param [Discorb::AllowedMentions, nil] other The object to merge.
    #
    # @return [Hash] The hash.
    #
    def to_hash(other = nil)
      payload = {
        parse: %w[everyone roles users],
      }
      replied_user = nil_merge(@replied_user, other&.replied_user)
      everyone = nil_merge(@everyone, other&.everyone)
      roles = nil_merge(@roles, other&.roles)
      users = nil_merge(@users, other&.users)
      payload[:replied_user] = replied_user
      payload[:parse].delete("everyone") if everyone == false
      if (roles == false) || roles.is_a?(Array)
        payload[:roles] = roles.map { |u| u.id.to_s } if roles.is_a? Array
        payload[:parse].delete("roles")
      end
      if (users == false) || users.is_a?(Array)
        payload[:users] = users.map { |u| u.id.to_s } if users.is_a? Array
        payload[:parse].delete("users")
      end
      payload
    end

    def nil_merge(*args)
      args.each do |a|
        return a unless a.nil?
      end
      nil
    end
  end
end
