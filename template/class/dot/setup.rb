# frozen_string_literal: true
include T("templates/module/dot")

def init
  super
  sections.push :superklass
end
