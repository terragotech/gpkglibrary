require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name             = 'react-native-geo-package-library'
  s.version          = package['version']
  s.summary          = package['description']
  s.license          = package['license']
  s.homepage         = package['homepage']
  s.authors          = 'Horcrux Chen'
  s.platforms        = { :ios => "9.0", :tvos => "9.2" }
  s.source           = { :git => 'https://github.com/terragotech/gpkglibrary.git', :tag => "v#{s.version}" }
  s.source_files     = 'ios/**/*.{h,m}'
  s.requires_arc     = true
  s.dependency         'React'
end
