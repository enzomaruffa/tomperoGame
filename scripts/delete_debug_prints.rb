#!/usr/bin/env ruby
# Second-pass cleanup: delete the remaining print() debug-spam lines across
# the GameScene + waiting-room + factory paths. These are dev breadcrumbs
# from 2019 that never got cleaned up — actual error/warning logs already
# migrated to Log.x in earlier PRs.
#
# Intentionally skips:
# - Tompero/Logger/ConsoleDebugLogger.swift  (print() is the logger sink)
# - Tompero/Networking/*  (already on Log.network)
# - anything that mentions Log. (already converted)

SKIP_PATHS = [
  'Tompero/Logger/ConsoleDebugLogger.swift'
]

TARGETS = %w[
  Tompero/AnalyticsEventLogger.swift
  Tompero/Networking/LANConnectionManager.swift
  Tompero/GameScene/IngredientNode.swift
  Tompero/GameScene/PlateNode.swift
  Tompero/GameScene/GameScene.swift
  Tompero/GameScene/MovableSpriteNode.swift
  Tompero/GameScene/TappableSpriteNode.swift
  Tompero/GameScene/OrderListNode.swift
  Tompero/Controller/WaitingRoomViewController.swift
  Tompero/Controller/InicialViewController.swift
  Tompero/Controller/StatisticsViewController.swift
]

# Glob the procedural-gen directory too.
Dir.glob('Tompero/Model/**/*.swift').each { |p| TARGETS << p }
Dir.glob('Tompero/Model/Procedural Generation/*.swift').each { |p| TARGETS << p }
Dir.glob('Tompero/Sound/*.swift').each { |p| TARGETS << p }

TARGETS.uniq.each do |path|
  next if SKIP_PATHS.include?(path)
  next unless File.exist?(path)
  src = File.read(path)
  changed = 0
  out = src.each_line.reject do |line|
    if line =~ /^\s*print\(/ && !line.include?('Log.')
      changed += 1
      true
    else
      false
    end
  end.join
  if changed > 0
    File.write(path, out)
    puts "#{path}: -#{changed} prints"
  end
end
