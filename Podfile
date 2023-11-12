# Uncomment the next line to define a global platform for your project
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
source 'https://github.com/webrtc-sdk/Specs.git'
platform :ios, '13.0'

target 'THK-IM-IOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end

  # Pods for THK-IM-IOS
  pod 'SnapKit', '5.6.0'
  pod 'WCDB.swift', '2.0.1'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod "RxGesture", '4.0.4'
  pod 'CocoaLumberjack/Swift', '3.8.2'
  pod 'Starscream', '4.0.4'
  pod 'Alamofire', '5.8.1'
  pod 'Moya/RxSwift', '15.0'
  pod 'Kingfisher', '7.0'
  pod 'SwiftEventBus', :tag => '5.1.0', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  pod 'ZLPhotoBrowser', '4.4.6'
  pod 'YbridOpus', '0.8.0'
  pod 'YbridOgg', '0.8.0'
  pod 'GDPerformanceView-Swift', '= 2.1.1'
  pod 'BadgeSwift', '8.0'
  pod 'WebRTC-SDK', '114.5735.04'

end
