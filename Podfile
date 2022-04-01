# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

workspace 'iMEGA'

abstract_target 'iMEGA' do
  pod 'GKContactImage', :git => 'https://github.com/meganz/GKContactImage.git'

  target 'MEGA' do
    # Pods for MEGA
    pod 'YYCategories'
    pod 'SAMKeychain'
    pod 'DateTools'
    pod 'JustPieChart'
    pod 'SwiftGen'

    target 'MEGAUnitTests' do
      inherit! :search_paths
      # Pods for testing
    end

  end

  target 'MEGANotifications' do
    # Pods for MEGANotifications
    pod 'SAMKeychain'
    pod 'DateTools'
    
  end

  target 'MEGAPicker' do
    # Pods for MEGAPicker
    pod 'YYCategories'
    pod 'SAMKeychain'
    pod 'DateTools'

  end

  target 'MEGAPickerFileProvider' do
    # Pods for MEGAPickerFileProvider
    pod 'SAMKeychain'

  end

  target 'MEGAShare' do
    # Pods for MEGAShare
    pod 'YYCategories'
    pod 'SAMKeychain'
    pod 'DateTools'

  end
  
  target 'MEGAIntent' do
    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAWidgetExtension' do
    # Pods for MEGAWidgetExtension
    pod 'YYCategories'
    pod 'SAMKeychain'
    pod 'DateTools'

  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end

  end
end
