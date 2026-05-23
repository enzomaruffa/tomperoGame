#!/usr/bin/env ruby
# Adds one .swift file to the Networking group and the Tompero target. Pass
# the basename (e.g. LANSecurity.swift) as the only arg.

require 'xcodeproj'

basename = ARGV.first or abort "usage: add_networking_file.rb <basename>"

project = Xcodeproj::Project.open('Tompero.xcodeproj')
target = project.targets.find { |t| t.name == 'Tompero' }
group  = project.main_group.find_subpath('Tompero/Networking', false)
abort "Networking group missing" unless group

if group.files.any? { |f| f.path == basename }
  puts "already present"
  exit 0
end

ref = group.new_reference(basename)
target.add_file_references([ref])
project.save
puts "added #{basename}"
