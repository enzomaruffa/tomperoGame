platform :ios, '15.0'

target 'Tompero' do
  use_frameworks!

  pod 'SwiftLint'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'

  target 'TomperoTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
