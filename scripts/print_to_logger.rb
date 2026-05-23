#!/usr/bin/env ruby
# Mechanical sweep: replace `print("[Foo] msg")` with `Log.<category>.debug("msg")`
# and bare `print(error.localizedDescription)` with an error-level log. Per-file
# category mapping is conservative — anything not in `MAP` is left alone for a
# human to triage.

MAP = {
  'Tompero/Game Connection/GameConnectionManager.swift' => :network,
  'Tompero/Controller/WaitingRoomViewController.swift' => :network,
  'Tompero/Controller/InicialViewController.swift' => :ui,
  'Tompero/Controller/StatisticsViewController.swift' => :game,
  'Tompero/Model/Procedural Generation/GameRuleFactory.swift' => :game,
  'Tompero/GameScene/GameScene.swift' => :game,
  'Tompero/GameScene/IngredientNode.swift' => :game,
  'Tompero/GameScene/PlateNode.swift' => :game,
  'Tompero/GameScene/OrderListNode.swift' => :game,
  'Tompero/GameScene/MovableSpriteNode.swift' => :game,
  'Tompero/Model/Ingredient.swift' => :game,
  'Tompero/AnalyticsEventLogger.swift' => :analytics,
  'Tompero/Sound/MusicPlayer.swift' => :audio,
  'Tompero/Sound/CustomAudioPlayer.swift' => :audio
}

PREFIXED_PRINT = /^(\s*)print\("\[[A-Za-z][A-Za-z0-9._]*\][^"]*"\s*((?:\+[^)]*)?)\)\s*$/
ANY_PRINT      = /^(\s*)print\((.+)\)\s*$/

def replace_in(path, category)
  return unless File.exist?(path)
  src = File.read(path)
  changed = 0
  out = src.each_line.map do |line|
    if line =~ /^(\s*)print\("\[[^\]]+\]\s*([^"]*)"\s*\)\s*$/
      changed += 1
      "#{$1}Log.#{category}.debug(\"#{$2.gsub('"', '\\"')}\")\n"
    elsif line =~ /^(\s*)print\(error\.localizedDescription\)\s*$/
      changed += 1
      "#{$1}Log.#{category}.error(\"\\(error.localizedDescription, privacy: .public)\")\n"
    elsif line =~ /^(\s*)print\("\[[^\]]+\]\s*(.+)"\)\s*$/
      changed += 1
      "#{$1}Log.#{category}.debug(\"#{$2.gsub('"', '\\"')}\")\n"
    else
      line
    end
  end.join
  if changed > 0
    File.write(path, out)
    puts "#{path}: #{changed} prints"
  end
end

MAP.each { |path, cat| replace_in(path, cat) }
