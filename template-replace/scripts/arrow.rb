def replace_arrow(dir)
  Dir.glob("#{dir}/**/*.html") do |file|
    content = File.read(file)
    content.gsub!("  &#x21d2; ", " -&gt; ")
    File.write(file, content, mode: "wb")
  end
end
