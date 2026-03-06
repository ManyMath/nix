Pod::Spec.new do |s|
  s.name             = 'nix'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Nix environment detection on iOS.'
  s.description      = 'Reports Nix as unavailable on iOS (Nix requires a Unix userland).'
  s.homepage         = 'https://github.com/sneurlax/nix'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'sneurlax' => 'sneurlax@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
