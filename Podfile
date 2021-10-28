# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

workspace 'iMEGA'

abstract_target 'iMEGA' do
  pod 'SDWebImageWebPCoder'
  pod 'Firebase/Crashlytics'
  pod 'PureLayout', :git => 'https://github.com/PureLayout/PureLayout.git'
  pod 'GKContactImage', :git => 'https://github.com/meganz/GKContactImage.git'

  target 'MEGA' do
    # Pods for MEGA
    pod 'MessageKit'
    pod 'PanModal', :git => 'https://github.com/ilia3546/PanModal.git', :commit => 'ba721e8'
    pod 'FlexLayout'
    pod 'PinLayout'
    pod 'ISEmojiView', :git => 'https://github.com/isaced/ISEmojiView.git', :tag => '0.2.6'
    pod 'Haptica'
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    pod 'CHTCollectionViewWaterfallLayout'
    pod 'Keyboard+LayoutGuide'
    pod 'YYCategories'
    pod 'SAMKeychain'
    
    # Pods for Debug only
    pod 'FLEX', :configurations => ['Debug']

    target 'MEGAUnitTests' do
      inherit! :search_paths
      # Pods for testing
    end

  end

  target 'MEGANotifications' do
    # Pods for MEGANotifications
    pod 'SAMKeychain'
    
  end

  target 'MEGAPicker' do
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGAPicker
    pod 'YYCategories'
    pod 'SAMKeychain'

  end

  target 'MEGAPickerFileProvider' do
    # Pods for MEGAPickerFileProvider
    pod 'SAMKeychain'

  end

  target 'MEGAShare' do
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGAShare
    pod 'YYCategories'
    pod 'SAMKeychain'

  end
  
  target 'MEGAIntent' do
    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAWidgetExtension' do
    pod 'YYCategories'
    pod 'SAMKeychain'
    # Pods for MEGAWidgetExtension

  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end

  end
end
