Pod::Spec.new do |s|
  s.name             = 'Alloy'
  s.version          = '0.1.0'
  s.summary          = 'Small utils for Metal framework'
  s.homepage         = 'https://github.com/s1ddok/Alloy'
  s.author           = { 'Andrey Volodin' => 'siddok@gmail.com' }
  s.source           = { :git => 'https://github.com/s1ddok/Alloy.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.11'
  s.source_files = 'Alloy/**/*.{swift}'
  s.frameworks = 'Metal'
end
