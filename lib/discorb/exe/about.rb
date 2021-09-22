# description: Show information of discorb.

puts "  disco\e[31mrb\e[m -  A new Discord API wrapper in Ruby.  \n\n"

informations = {
  "GitHub" => "https://github.com/discorb-lib/discorb",
  "Documentation" => "https://discorb-lib.github.io",
  "RubyGems" => "https://rubygems.org/gems/discorb",
  "Changelog" => "https://discorb-lib.github.io/file.Changelog.html",
  "License" => "MIT License",
}

informations.each do |key, value|
  puts "\e[90m#{key.rjust(informations.keys.map(&:size).max)}:\e[m #{value}"
end
