
Pod::Spec.new do |s|
  s.name             = 'Retryable'
  s.version          = '0.3.0'
  s.summary          = 'Retryable iOS automation tests.'

  s.description      = <<-DESC
Retryable iOS automation tests.
                       DESC

  s.homepage         = 'https://github.com/kanecheshire/Retryable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kanecheshire' => '@kanecheshire' }
  s.source           = { :git => 'https://github.com/kanecheshire/Retryable.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/kanecheshire'

  s.ios.deployment_target = '8.0'
  s.swift_version = '5.0'

  s.source_files = 'Retryable/Classes/**/*'
  s.frameworks = 'XCTest'
end
