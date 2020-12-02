# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
workspace 'iMEGA'

abstract_target 'iMEGA' do
  use_frameworks!
  pod 'YYWebImage'
  # In iOS 14 there is this issue of image not being displayed 'YYAnimatedImageView'. The below repo fixes this issue. Please delete the below line of code once the issue is fixed in the main repository.
  pod 'YYImage/WebP', :git => 'https://github.com/sundayfun/YYImage.git'

  target 'MEGA' do
    # Pods for MEGA
    pod 'MessageKit', :git => 'https://github.com/lhr000lhrmega/MessageKit.git'
    pod 'PanModal'
    pod 'FlexLayout'
    pod 'PinLayout'
    pod 'ISEmojiView', :git => 'https://github.com/isaced/ISEmojiView.git', :tag => '0.2.6'
    pod 'Haptica'
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    pod 'CHTCollectionViewWaterfallLayout/Swift'
    pod 'YYCategories'
    # Pods for MEGA
    pod 'Firebase/Crashlytics'

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

  end

  target 'MEGAPickerFileProvider' do
    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAShare' do
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGAShare

  end

end
