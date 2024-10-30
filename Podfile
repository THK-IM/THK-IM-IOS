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
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end

  ## Pods for THK-IM-IOS/IMCore
  pod 'WCDB.swift', '2.1.1'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'CocoaLumberjack/Swift', '3.8.2'
  pod 'Starscream', '4.0.6'
  pod 'Moya/RxSwift', '15.0'
  pod 'CryptoSwift', '~> 1.8.1'
  
  
  ## Pods for THK-IM-IOS/IMUI
  pod 'Kingfisher', '7.10.0'
  pod 'RxGesture', '4.0.4'
  pod 'SnapKit', '5.6.0'
  pod 'Alamofire', '5.8.1'
  pod 'BadgeSwift', '8.0'
  pod 'SVGKit'
  pod 'ProgressHUD'
  pod 'JDStatusBarNotification'
  pod 'SwiftEntryKit'
  
  ## Pods for THK-IM-IOS/IMPreviewer
  
  ## Pods for THK-IM-IOS/IMProvider
  pod 'ZLPhotoBrowser', '4.4.6'
  pod 'YbridOpus', '0.8.0'
  pod 'YbridOgg', '0.8.0'
  
  pod 'SJVideoPlayer'
  pod 'SJUIKit/SQLite3'
  pod 'SJMediaCacheServer'
  
  ## Pods for THK-IM-IOS/IMLive
  pod 'WebRTC-SDK', '=125.6422.05'
  
  
  ## Pods for App
  pod 'GDPerformanceView-Swift', '= 2.1.1'

end
