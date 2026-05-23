#!/usr/bin/env ruby
# Adds one file under Tompero/Resources/ to the project's Resources build
# phase. Pass the relative path under Resources (e.g. Localizable.xcstrings).

require 'xcodeproj'

basename = ARGV.first or abort "usage: add_resource_file.rb <basename>"

project = Xcodeproj::Project.open('Tompero.xcodeproj')
target  = project.targets.find { |t| t.name == 'Tompero' }
group   = project.main_group.find_subpath('Tompero/Resources', false)
abort "Resources group missing" unless group

if group.files.any? { |f| f.path == basename }
  puts "already present"
  exit 0
end

ref = group.new_reference(basename)
target.resources_build_phase.add_file_reference(ref)
project.save
puts "added #{basename} as resource"
