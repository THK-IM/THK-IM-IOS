#
#  Be sure to run `pod spec lint THK-IM-IOS.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "THK-IM-IOS"
  spec.version      = "0.2.7"
  spec.summary      = "A short description of THK-IM-IOS."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  # spec.description  = <<-DESC
  #                  DESC

  spec.homepage     = "https://github.com/THK-IM"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See https://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  spec.license      = "MIT"
  # spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.author             = { "vizoss" => "think220216@gmail.com" }
  # Or just: spec.author    = "vizoss"
  # spec.authors            = { "vizoss" => "think220216@gmail.com" }
  # spec.social_media_url   = "https://twitter.com/vizoss"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  spec.platform     = :ios, "13.0"

  #  When using multiple platforms
  spec.ios.deployment_target = "13.0"
  spec.osx.deployment_target = "10.13"
  spec.watchos.deployment_target = "7.0"
  spec.tvos.deployment_target = "12.4"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/THK-IM/THK-IM-IOS.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  spec.source_files  = "THK-IM-IOS-SDK/**/*.swift"


  spec.requires_arc = true
  
  spec.default_subspec = 'IMCore'

  spec.subspec 'IMCore' do |core|
    core.source_files = 'THK-IM-IOS-SDK/IMCore/**/*.swift',
    core.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'MobileCoreServices', 'AVFoundation', 'ImageIO'
    core.dependency 'WCDB.swift', '2.1.1'
    core.dependency 'RxSwift', '6.8.0'
    core.dependency 'RxCocoa', '6.8.0'
    core.dependency 'CocoaLumberjack/Swift', '3.8.2'
    core.dependency 'Starscream', '4.0.8'
    core.dependency 'Moya/RxSwift', '15.0'
    core.dependency 'CryptoSwift', '~> 1.8.1'
  end

  spec.subspec 'IMUI' do |ui|
    ui.source_files = 'THK-IM-IOS-SDK/IMUI/**/*.swift'
    # ui.resource = 'THK-IM-IOS-SDK/IMUI/Resources/*.xcassets'
    ui.resource_bundles = {
      'IMUI' => ['THK-IM-IOS-SDK/IMUI/Resources/*'],
    }
    ui.dependency 'Kingfisher', '7.10.0'
    ui.dependency 'RxGesture', '4.0.4'
    ui.dependency 'SnapKit', '5.7.1'
    ui.dependency 'Alamofire', '5.10.1'
    ui.dependency 'BadgeSwift', '8.0'
    ui.dependency 'THK-IM-IOS/IMCore'
    ui.dependency 'ProgressHUD'
    ui.dependency 'SVGKit'
    ui.dependency 'JDStatusBarNotification'
    ui.dependency 'SwiftEntryKit'
    ui.dependency 'SJVideoPlayer'
    ui.dependency 'SJUIKit/SQLite3'
    ui.dependency 'SJMediaCacheServer'
  end

  spec.subspec 'IMPreviewer' do |previewer|
    previewer.source_files = 'THK-IM-IOS-SDK/IMPreviewer/**/*.swift'
    previewer.dependency 'THK-IM-IOS/IMUI'
  end

  spec.subspec 'IMProvider' do |provider|
    provider.source_files = 'THK-IM-IOS-SDK/IMProvider/**/*.swift'
    provider.dependency 'THK-IM-IOS/IMUI'
    provider.dependency 'ZLPhotoBrowser', '4.5.6'
    provider.vendored_frameworks = 'Third/YBridOgg.xcframework', 'Third/YBridOpus.xcframework'
  end

  spec.subspec 'IMLive' do |live|
    live.source_files = 'THK-IM-IOS-SDK/IMLive/**/*.swift'
    live.resource = 'THK-IM-IOS-SDK/IMLive/Resources/*.xcassets'
    live.dependency 'THK-IM-IOS/IMUI'
    live.dependency 'WebRTC-SDK', '=125.6422.06'
  end

end
