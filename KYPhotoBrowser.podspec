Pod::Spec.new do |s|

  s.name         = "KYPhotoBrowser"
  s.version      = "0.1"
  s.summary      = "A light PhotoBrowser in Swift 3 like IDMPhotoBrowser"
  s.homepage     = "https://github.com/kirayamato1989"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors      = { "kirayamato" => "1027610607@qq.com" }

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/kirayamato1989/KYPhotoBrowser.git", :tag => s.version }
  
  s.source_files  = ["KYPHotoBrowser/*.swift"]
  
  s.requires_arc = true
  s.dependency     'Kingfisher'
  s.dependency     'KYCircularProgress'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
