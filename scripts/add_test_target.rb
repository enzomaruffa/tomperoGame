#!/usr/bin/env ruby
# Wires a TomperoTests XCTest target into Tompero.xcodeproj. Hosted by the
# Tompero app, so the test bundle inherits the app's Pods via TEST_HOST and
# the @testable import works without re-linking Pods.

require 'xcodeproj'

PROJECT_PATH = 'Tompero.xcodeproj'
APP_TARGET = 'Tompero'
TEST_TARGET = 'TomperoTests'
TEST_DIR = 'TomperoTests'

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.targets.any? { |t| t.name == TEST_TARGET }
  puts "Target '#{TEST_TARGET}' already exists; nothing to do."
  exit 0
end

app_target = project.targets.find { |t| t.name == APP_TARGET }
abort("Could not find target '#{APP_TARGET}'") unless app_target

development_team = app_target.build_configurations.first.build_settings['DEVELOPMENT_TEAM']

test_target = project.new_target(
  :unit_test_bundle,
  TEST_TARGET,
  :ios,
  '15.0',
  project.products_group,
  :swift
)

# Build settings the unit-test bundle needs to be hosted by the app target.
test_target.build_configurations.each do |config|
  bs = config.build_settings
  bs['SWIFT_VERSION'] = '5.10'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  bs['INFOPLIST_FILE'] = "#{TEST_DIR}/Info.plist"
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.enzomaruffa.spacespice.tests'
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['BUNDLE_LOADER'] = '$(TEST_HOST)'
  bs['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SpaceSpice.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SpaceSpice'
  bs['DEVELOPMENT_TEAM'] = development_team if development_team
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']
  bs['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
end

# Source files
test_group = project.main_group.find_subpath(TEST_DIR, true)
test_group.set_source_tree('<group>')
test_group.set_path(TEST_DIR)

Dir.glob("#{TEST_DIR}/*.swift").sort.each do |path|
  basename = File.basename(path)
  next if test_group.files.any? { |f| f.path == basename }
  file_ref = test_group.new_reference(basename)
  test_target.add_file_references([file_ref])
end

# Test bundle is hosted by the app — build dependency makes the order right.
test_target.add_dependency(app_target)

project.save
puts "Added '#{TEST_TARGET}' target. Sources:"
test_target.source_build_phase.files.each { |f| puts "  - #{f.display_name}" }
