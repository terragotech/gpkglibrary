require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name             = 'react-native-geo-package-library'
  s.version          = package['version']
  s.summary          = "https://github.com/terragotech/gpkglibrary"
  s.license          = package['license']
  s.homepage         = "https://github.com/terragotech/gpkglibrary"
  s.authors          = 'SunilKarthick'
  s.platforms        = { :ios => "9.0" }
  s.source           = { :git => 'https://github.com/terragotech/gpkglibrary.git', :tag => "v#{s.version}" }
  s.source_files     = 'ios/**/*.{h,m}'
  s.requires_arc     = true
  s.dependency         'React'
end