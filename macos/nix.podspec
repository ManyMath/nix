Pod::Spec.new do |s|
  s.name             = 'nix'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for Nix environment detection on macOS.'
  s.description      = 'Detects Nix installation and lists packages on macOS.'
  s.homepage         = 'https://github.com/sneurlax/nix'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'sneurlax' => 'sneurlax@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
