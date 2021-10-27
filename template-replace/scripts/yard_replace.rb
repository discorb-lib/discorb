require "yard"

def yard_replace(dir, version)
  sha = `git rev-parse HEAD`.strip
  tag = `git describe --exact-match #{sha}`
  tag = tag.empty? ? "(main)" : tag.strip
  Dir.glob("#{dir}/**/*.html") do |file|
    next if (m = file.match(/[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?/)) && m[0] != version
    contents = File.read(file)
    contents.gsub!(Regexp.new(<<-'HTML1'), <<-HTML2)
      <div id="footer">
  Generated on .+ by
  <a href="http://yardoc.org" title="Yay! A Ruby Documentation Tool" target="_parent">yard</a>
  .+\.
</div>
    HTML1
    <div id="footer">
    Generated from <a href="https://github.com/discorb-lib/discorb/tree/#{sha}"><code>#{sha}</code></a>, version #{tag}, with YARD #{YARD::VERSION}.
    </div>
    HTML2
    contents.gsub!(<<-'HTML3', <<-HTML4)
<h1 class="noborder title">Documentation by YARD 0.9.26</h1>
    HTML3
    HTML4
    contents.gsub!(/Documentation by YARD \d+\.\d+\.\d+/, "discorb documentation for #{version}")
    File.write(file, contents)
  end
end
