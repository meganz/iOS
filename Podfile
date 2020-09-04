# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
workspace 'iMEGA'

abstract_target 'iMEGA' do
  use_frameworks!

  pod 'YYWebImage'

  target 'MEGA' do
    # Comment the next line if you don't want to use dynamic frameworks
    pod 'MessageKit', :git => 'https://github.com/lhr000lhrmega/MessageKit.git'
    pod 'PanModal'
    pod 'FlexLayout'
    pod 'PinLayout'
    pod 'ISEmojiView', :git => 'https://github.com/isaced/ISEmojiView.git', :tag => '0.2.6'
    pod 'Haptica'
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'
    # Pods for MEGA

    target 'MEGAUnitTests' do
      inherit! :search_paths
      # Pods for testing
    end

  end

  target 'MEGANotifications' do
    # Comment the next line if you don't want to use dynamic frameworks

    # Pods for MEGANotifications

  end

  target 'MEGAPicker' do
    # Comment the next line if you don't want to use dynamic frameworks
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'

    # Pods for MEGAPicker

  end

  target 'MEGAPickerFileProvider' do
    # Comment the next line if you don't want to use dynamic frameworks

    # Pods for MEGAPickerFileProvider

  end

  target 'MEGAShare' do
    # Comment the next line if you don't want to use dynamic frameworks
    pod 'DZNEmptyDataSet', :git => 'https://github.com/meganz/DZNEmptyDataSet.git', :commit => '3db6295'

    # Pods for MEGAShare

  end

end
