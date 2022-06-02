platform :ios, '12.0'
inhibit_all_warnings!
use_frameworks!

# uncomment this only when you need to install AudioKit
# source 'https://github.com/AudioKit/Specs.git'

def main_pods
  pod 'AudioKit', '~> 4.10.0'
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Functions'
  pod 'Firebase/Storage'
  pod 'FirebaseFirestoreSwift'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/DynamicLinks'
  pod 'SnapSDK', :subspecs => ['SCSDKLoginKit', 'SCSDKCreativeKit']
  pod 'pop'
  pod 'BonMot'
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
  pod 'OpenTok'
  pod 'mobile-ffmpeg-full', '~> 4.2'
  pod 'Branch'
  pod "PaperTrailLumberjack/Swift"
  pod 'UIImageColors'
  pod "Atributika"
  pod 'TikTokOpenSDK'
  pod 'VFCabbage'
  pod 'lottie-ios'
end

target 'sup' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for sup
  main_pods
end

target 'OneSignalNotificationServiceExtension' do
  pod 'OneSignal', '>= 2.11.2', '< 3.0'
end
