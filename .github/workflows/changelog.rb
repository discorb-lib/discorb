changelog = File.read("./Changelog.md")
releases = changelog.split("## ")
releases_hash = releases.map do |release|
  release_name = "v" + release.split("\n")[0]
  release_body = release.split("\n")[1..-1].join("\n").strip
  [release_name, release_body]
end.to_h

release_version = ENV["GITHUB_REF"].split("/")[-1]

release_body = releases_hash[release_version]
puts "::set-output name=release_body::#{release_body.gsub("\n", "\\n")}"
