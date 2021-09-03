def replace_sidebar(file)
  html = File.read(file)
  files_html = <<-HTML
            <span><a target="_self" href="file_list.html">
              Files
            </a></span>
  HTML
  index = html.index(files_html)
  html.insert(index + files_html.length, '<!--od--><span><a target="_self" href="version_list.html">Versions</a></span><!--eod-->')
  File.write(file, html)
end
