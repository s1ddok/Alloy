Pod::Spec.new do |s|
  s.name = 'Alloy'
  s.version = '0.16.3'

  s.summary = 'Nano helpers for Metal framework'
  s.homepage = 'https://github.com/s1ddok/Alloy'

  s.author = { 'Andrey Volodin' => 'siddok@gmail.com' }
  s.social_media_url = 'http://twitter.com/s1ddok'

  s.source = {
    :git => 'https://github.com/s1ddok/Alloy.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.swift_version = '5.3'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/Alloy/Core/**/*.{swift}'
    core.frameworks = 'Metal', 'CoreVideo'
  end

  s.subspec 'Shaders' do |shaders|
    shaders.source_files = 'Sources/Alloy/Shaders/*.{metal,h}', 'Sources/Alloy/Encoders/*.{swift}', 'Sources/Alloy/Renderers/*.{swift}', 'Sources/AlloyShadersSharedTypes/*.{h}'
    shaders.frameworks = 'Metal', 'CoreVideo'
    shaders.dependency 'Alloy/Core'
  end

  s.subspec 'ML' do |ml|
    ml.source_files = 'Sources/Alloy/ML/*.{swift}'
    ml.frameworks = 'Metal', 'MetalPerformanceShaders'
    ml.dependency 'Alloy/Core'
  end

  s.pod_target_xcconfig = {
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'NEEDS_BUNDLE_MODULE_DEFINITION'
  }

  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
end
