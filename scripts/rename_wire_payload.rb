#!/usr/bin/env ruby
# One-shot: remove the legacy MultipeerConnectivity Manager group from the
# pbxproj (only MCDataWrapper/MCDataType were left in it after the LAN swap)
# and add the renamed Networking/WirePayload.swift + WirePayloadType.swift to
# the app target's sources.

require 'xcodeproj'

PROJECT_PATH = 'Tompero.xcodeproj'

project = Xcodeproj::Project.open(PROJECT_PATH)
app_target = project.targets.find { |t| t.name == 'Tompero' }
abort "no Tompero target" unless app_target

# Drop the legacy group entirely (it had two .swift files inside that we
# already deleted from disk).
legacy = project.main_group.find_subpath('Tompero/MultipeerConnectivity Manager', false)
if legacy
  legacy.files.each do |f|
    f.build_files.each do |bf|
      bf.referrers.each { |r| r.remove_from_project }
      bf.remove_from_project
    end
    f.remove_from_project
  end
  legacy.remove_from_project
  puts "removed legacy group 'MultipeerConnectivity Manager'"
end

# Add the new files to the Networking group.
networking = project.main_group.find_subpath('Tompero/Networking', false)
abort "Networking group missing" unless networking

%w[WirePayload.swift WirePayloadType.swift].each do |name|
  next if networking.files.any? { |f| f.path == name }
  ref = networking.new_reference(name)
  app_target.add_file_references([ref])
  puts "added #{name}"
end

project.save
