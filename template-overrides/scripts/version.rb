def build_version_sidebar(dir)
  raw = File.read("template-overrides/resources/version_list.html")
  template = raw.match(/<!--template-->(.*)<!--endtemplate-->/m)[1]
  raw.gsub!(template, "")
  res = +""
  `git tag`.force_encoding("utf-8").split("\n").each.with_index do |dir, i|
    version = dir.delete_prefix("v")
    res += template.gsub("!version!", version).gsub("!eo!", i % 2 == 0 ? "even" : "odd")
  end
  File.write(dir + "/version_list.html", raw.gsub("<!--replace-->", res))
end
