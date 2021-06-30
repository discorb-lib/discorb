# frozen_string_literal: true

require_relative 'common'

module Discorb
  class Activity
    @types = {
      playing: 0,
      streaming: 1,
      listening: 2,
      watching: 3,
      competing: 5
    }

    def initialize(name, type = :playing, url = nil)
      @name = name
      @type = @types[type]
      @url = url
    end

    def to_hash
      {
        name: @name,
        type: @type,
        url: @url
      }
    end
  end
end
