#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint music.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'music'
  s.version          = '1.0.0'
  s.summary          = 'Music Player'
  s.description      = <<-DESC
  Music player in Flutter.
                       DESC
  s.homepage         = 'https://github.com/salkuadrat/musicplayer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Salman S' => 'salkuadrat@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
