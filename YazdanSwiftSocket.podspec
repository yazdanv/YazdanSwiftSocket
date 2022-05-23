Pod::Spec.new do |s|
  s.name             = 'YazdanSwiftSocket'
  s.version          = '0.1.8'
  s.summary          = 'YazdanSwiftSocket is a Swift3 modern TCP & UDP Socket Library'


  s.description      = <<-DESC
                        this is YazdanSwiftSocket library that provides great features for TCP & UDP Sockets in Swift3 with modern syntax
                       DESC

  s.homepage         = 'https://github.com/yazdanv/YazdanSwiftSocket'
  s.license      = { :type => 'BSD' }
  s.author           = { 'Yazdan.xyz' => 'ymazdy@gmail.com' }
  s.source           = { :git => 'https://github.com/yazdanv/YazdanSwiftSocket.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/yazdanv'

  s.ios.deployment_target = '8.0'

  s.source_files = 'YazdanSwiftSocket/**/**/*'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }

end
