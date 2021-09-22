require "discorb"

client = Discorb::Client.new

SECTIONS = [
  ["About", <<~WIKI],
    Ruby is an interpreted, high-level, general-purpose programming language.
    It was designed and developed in the mid-1990s by Yukihiro "Matz" Matsumoto in Japan.\n\n
    Ruby is dynamically typed and uses garbage collection and just-in-time compilation.
    It supports multiple programming paradigms, including procedural, object-oriented, and functional programming.
    According to the creator, Ruby was influenced by Perl, Smalltalk, Eiffel, Ada, BASIC, and Lisp.
  WIKI
  ["Early concept", <<~WIKI],
    Matsumoto has said that Ruby was conceived in 1993.
    In a 1999 post to the ruby-talk mailing list, he describes some of his early ideas about the language:
    > I was talking with my colleague about the possibility of an object-oriented scripting language.
    > I knew Perl (Perl4, not Perl5), but I didn't like it really, because it had the smell of a toy language (it still has).
    > The object-oriented language seemed very promising. I knew Python then.
    > But I didn't like it, because I didn't think it was a true object-oriented language - OO features appeared to be add-on to the language.
    > As a language maniac and OO fan for 15 years, I really wanted a genuine object-oriented, easy-to-use scripting language. I looked for but couldn't find one.
    > So I decided to make it.
    Matsumoto describes the design of Ruby as being like a simple Lisp language at its core, with an object system like that of Smalltalk, blocks inspired by higher-order functions, and practical utility like that of Perl.
  WIKI
  ["First publication", <<~WIKI],
    The first public release of Ruby 0.95 was announced on Japanese domestic newsgroups on December 21, 1995.
    Subsequently, three more versions of Ruby were released in two days.
    The release coincided with the launch of the Japanese-language ruby-list mailing list, which was the first mailing list for the new language.

    Already present at this stage of development were many of the features familiar in later releases of Ruby, including object-oriented design, classes with inheritance, mixins, iterators, closures, exception handling and garbage collection.
  WIKI
].freeze

WIKIPEDIA_CREDIT = "(From: [Wikipedia](https://en.wikipedia.org/wiki/Ruby_(programming_language)))"

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.on :message do |message|
  next if message.author.bot?
  next unless message.content == "!ruby"

  options = SECTIONS.map.with_index { |section, i| Discorb::SelectMenu::Option.new("Page #{i + 1}", "sections:#{i}", description: section[0]) }
  message.channel.post(
    "Select a section", components: [Discorb::SelectMenu.new("sections", options)],
  )
end

client.on :select_menu_select do |response|
  next unless response.custom_id == "sections"

  id = response.value.delete_prefix("sections:")
  selected_section = SECTIONS[id.to_i]
  response.post(
    "**#{selected_section[0]}**\n" \
    "#{selected_section[1].strip}\n\n" \
    "#{WIKIPEDIA_CREDIT}", ephemeral: true,
  )
end

client.run(ENV["DISCORD_BOT_TOKEN"])
