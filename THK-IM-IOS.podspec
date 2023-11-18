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
  spec.version      = "0.0.1"
  spec.summary      = "A short description of THK-IM-IOS."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
                   DESC

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
  # spec.platform     = :ios, "5.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "5.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.source       = { :git => "https://github.com/THK-IM/THK-IM-IOS", :tag => "#{spec.version}" }


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
    core.source_files = 'THK-IM-IOS-SDK/IMCore/*.swift',
    core.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'MobileCoreServices'
    core.dependency 'AVFoundation', 'ImageIO'
    core.dependency 'WCDB.swift', '2.0.1'
    core.dependency 'RxSwift', '6.5.0'
    core.dependency 'RxCocoa', '6.5.0'
    core.dependency 'CocoaLumberjack/Swift', '3.8.2'
    core.dependency 'Starscream', '4.0.4'
    core.dependency 'Moya/RxSwift', '15.0'
    core.dependency 'Kingfisher', '7.10.0'
    core.dependency 'SwiftEventBus', :tag => '5.1.0', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  end

  spec.subspec 'IMUI' do |ui|
    ui.source_files = 'THK-IM-IOS-SDK/IMUI/*.swift'
    ui.dependency 'THK-IM-IOS/IMCore'
    ui.dependency 'SnapKit', '5.6.0'
    ui.dependency "RxGesture", '4.0.4'
    ui.dependency 'Alamofire', '5.8.1'
    ui.dependency 'BadgeSwift', '8.0'
  end

  spec.subspec 'IMPreviewer' do |previewer|
    provider.source_files = 'THK-IM-IOS-SDK/IMPreviewer/*.swift'
    preview.dependency 'THK-IM-IOS/IMUI'
    preview.dependency 'SnapKit', '5.6.0'
  end

  spec.subspec 'IMProvider' do |provider|
    provider.source_files = 'THK-IM-IOS-SDK/IMProvider/*.swift'
    provider.dependency 'THK-IM-IOS/IMUI'
    provider 'ZLPhotoBrowser', '4.4.6'
    provider 'YbridOpus', '0.8.0'
    provider 'YbridOgg', '0.8.0'
  end

end
