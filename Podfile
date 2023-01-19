# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'gat' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for gat
    pod 'QueryKit'
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'
    pod 'RxGesture', '~> 3.0'
    pod 'Alamofire', '~> 4.8.0'
    pod 'RxAlamofire', '~> 5.0'
    pod 'Action', '~> 4.0'
    pod 'APIKit', '~> 5.0'
    pod 'RealmSwift'
    pod 'FacebookCore'
    pod 'FacebookLogin'
    pod 'FacebookShare'
    pod 'SwiftyJSON', '~> 4.2.0'
    pod 'RxRealm', '~> 1.0'
    pod 'SDWebImage', '~> 4.4.3'
    pod 'GoogleMaps'
    pod 'GooglePlaces'
    pod 'MTBBarcodeScanner', '~> 5.0.8'
    pod 'ReachabilitySwift', '~> 4.3.0'
    pod 'HMSegmentedControl', '~> 1.5.5'
    pod 'Cosmos', '~> 18.0.1'
    pod 'Fakery', '~> 3.4.0'
    pod 'RxDataSources', '~> 4.0'
    pod 'SwiftyGif', '~> 4.2.0'
    pod 'ExpandableLabel', '~> 0.5.1'
#    pod 'JTMaterialSwitch', '~> 1.1'
    pod 'Firebase/Auth'
    pod 'Firebase/Core'
    pod 'Firebase/Messaging'
    pod 'Firebase/Database'
    pod 'Firebase/Firestore'
    pod 'Firebase/Crashlytics'
    pod 'Firebase/Analytics'
    pod 'ImagePicker', :git => 'https://github.com/jujien/ImagePicker'
    pod 'TwitterKit'
    pod 'GoogleSignIn'
    pod 'NVActivityIndicatorView', '~> 4.5.1'
    pod 'Fabric'
    pod 'Crashlytics', '~> 3.12.0'
    pod 'Google-Mobile-Ads-SDK'
    pod 'MBProgressHUD'
    pod 'WordPress-Aztec-iOS'
    pod 'WordPress-Editor-iOS'
    pod 'InputBarAccessoryView'
    pod 'SwiftSoup'
    pod 'lottie-ios'
    
    # Cache Image
    pod 'Kingfisher', '~> 5.12.0'
    
    # Quick set constraint
    pod 'SnapKit', '~> 5.0.0'
    # Top Swipe Menu
    pod 'SwipeMenuViewController'

    pod 'XLPagerTabStrip', '~> 9.0'
#    pod 'PullUpController'
    pod 'GradientProgressBar', '~> 2.0'
    pod 'BEMCheckBox'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if ['ImagePicker'].include? target.name
        config.build_settings['SWIFT_VERSION'] = '4.2'
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
      end
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
    end
    
  end
end

