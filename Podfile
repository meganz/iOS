# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
workspace 'iMEGA'

abstract_target 'iMEGA' do
  use_frameworks!
  pod 'SDWebImageWebPCoder'
  pod 'Firebase/Crashlytics'

  target 'MEGA' do
    # Pods for MEGA
    pod 'MessageKit', :git => 'https://github.com/lhr000lhrmega/MessageKit.git'
    pod 'PanModal'
    pod 'FlexLayout'
    pod 'PinLayout'
    pod 'ISEmojiView', :git => 'https://github.com/isaced/ISEmojiView.git', :tag => '0.2.6'
    pod 'Haptica'
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    pod 'CHTCollectionViewWaterfallLayout'

    pod 'YYCategories'
    
    # Pods for MEGA
    pod 'DoraemonKit/Core', '3.0.4', :configurations => ['Debug'] #Required
    pod 'DoraemonKit/WithGPS', '3.0.4', :configurations => ['Debug'] #Optional
    pod 'DoraemonKit/WithLoad', '3.0.4', :configurations => ['Debug'] #Optional
    pod 'GCDWebServer', :configurations => ['Debug']
    pod 'FMDB', :configurations => ['Debug']

    target 'MEGAUnitTests' do
      inherit! :search_paths
      # Pods for testing
    end

  end

  target 'MEGANotifications' do
    # Pods for MEGANotifications
    
  end

  target 'MEGAPicker' do
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGAPicker
    pod 'YYCategories'

  end

  target 'MEGAPickerFileProvider' do
    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAShare' do
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGAShare
    pod 'YYCategories'

  end
  
  target 'MEGAIntent' do
    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAWidgetExtension' do
    pod 'YYCategories'
    # Pods for MEGAWidgetExtension

  end
end
