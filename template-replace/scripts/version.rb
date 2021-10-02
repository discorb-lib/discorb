def build_version_sidebar(dir, version)
  raw = File.read("template-replace/resources/version_list.html")
  template = raw.match(/<!--template-->(.*)<!--endtemplate-->/m)[1]
  raw.gsub!(template, "")
  res = +""
  i = 0
  `git tag`.force_encoding("utf-8").split("\n").reverse.each.with_index do |tag|
    i += 1
    sha = `git rev-parse #{tag}`.force_encoding("utf-8").strip
    tag_version = tag.delete_prefix("v")
    cls = i % 2 == 0 ? "even" : "odd"
    if tag_version == version
      cls += " current"
    end
    res += template.gsub("!version!", tag_version).gsub("!path!", "/" + version).gsub("!class!", cls).gsub("!sha!", sha)
  end
  i += 1
  cls = i % 2 == 0 ? "even" : "odd"
  if version == "main"
    cls += " current"
  end
  res.insert 0, template.gsub("!version!", "Main").gsub("!path!", "/main").gsub("!class!", cls).gsub("!sha!", "Latest on GitHub")
  i += 1
  cls = i % 2 == 0 ? "even" : "odd"
  res.insert 0, template.gsub("!version!", "Latest").gsub("!path!", "/").gsub("!class!", cls).gsub("!sha!", "Latest on RubyGems")
  File.write(dir + "/version_list.html", raw.gsub("<!--replace-->", res))
end
