# frozen_string_literal: true
# @private
def sputs(text)
  puts "\e[92m#{text}\e[m"
end

# @private
def eputs(text)
  puts "\e[91m#{text}\e[m"
end

# @private
def iputs(text)
  puts "\e[90m#{text}\e[m"
end
