# Adds the DaylyWidget WidgetKit extension to ios/Runner.xcodeproj (idempotent).
# Run: ruby tool/ios_add_widget.rb   (needs `gem install xcodeproj`)
require 'xcodeproj'

root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.open(File.join(root, 'ios/Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }

# Runner: App Group entitlement and the same header flag as the pods.
runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  c.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  c.build_settings['CLANG_ENABLE_EXPLICIT_MODULES'] = 'NO'
end
runner_group = project.main_group.find_subpath('Runner')
unless runner_group.files.any? { |f| f.path == 'Runner.entitlements' }
  runner_group.new_file('Runner.entitlements')
end

name = 'DaylyWidget'
widget = project.targets.find { |t| t.name == name }
unless widget
  widget = project.new_target(:app_extension, name, :ios, '16.0', nil, :swift)
  group = project.main_group.find_subpath(name, true)
  group.set_source_tree('<group>')
  group.set_path(name)
  swift = group.new_file('DaylyWidget.swift')
  group.new_file('Info.plist')
  group.new_file('DaylyWidget.entitlements')
  widget.add_file_references([swift])
  %w[WidgetKit SwiftUI].each do |fw|
    ref = project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
    widget.frameworks_build_phase.add_file_reference(ref)
  end

  xcconfig = project.main_group.find_subpath('Flutter').new_file('WidgetExtension.xcconfig')
  widget.build_configurations.each do |c|
    c.base_configuration_reference = xcconfig
    s = c.build_settings
    s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.dayly.app.DaylyWidget'
    s['PRODUCT_NAME'] = '$(TARGET_NAME)'
    s['INFOPLIST_FILE'] = 'DaylyWidget/Info.plist'
    s['CODE_SIGN_ENTITLEMENTS'] = 'DaylyWidget/DaylyWidget.entitlements'
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    s['SWIFT_VERSION'] = '5.0'
    s['TARGETED_DEVICE_FAMILY'] = '1,2'
    s['SKIP_INSTALL'] = 'YES'
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
    s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
    s['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = ''
    s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  end

  runner.add_dependency(widget)
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
  bf = embed.add_file_reference(widget.product_reference, true)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  # Must run before Flutter's "Thin Binary" script, or Xcode reports a cycle.
  phases = runner.build_phases
  phases.delete(embed)
  thin = phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' } || phases.length
  phases.insert(thin, embed)
end

project.save
puts "ok: #{project.targets.map(&:name).join(', ')}"
