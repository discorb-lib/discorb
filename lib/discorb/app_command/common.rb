# frozen_string_literal: true

module Discorb
  #
  # Handles application commands.
  #
  module ApplicationCommand
    # @return [Array<String>] List of valid locales.
    VALID_LOCALES = %w[da de en-GB en-US es-ES fr hr it lt hu nl no pl pt-BR ro fi sv-SE vi tr cs el bg ru uk hi th zh-CN ja zh-TW ko].freeze

    module_function

    def modify_localization_hash(hash)
      hash.to_h do |rkey, value|
        key = rkey.to_s.gsub("_", "-")
        raise ArgumentError, "Invalid locale: #{key}" if VALID_LOCALES.none? { |valid| valid.downcase == key.downcase } && key != "default"
        [key == "default" ? "default" : VALID_LOCALES.find { |valid| valid.downcase == key.downcase }, value]
      end
    end
  end
end
