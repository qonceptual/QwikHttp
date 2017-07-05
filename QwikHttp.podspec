#
# Be sure to run `pod lib lint QwikHttp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "QwikHttp"
s.version          = "1.7.11.3"
s.summary          = "QwikHTTP is a simple, super powerful Http Networking library."
s.description      = <<-DESC
QwikHttp is based around that making HTTP networking calls to your Rest APIs should be quick,
easy, and clean. Qwik Http allows you to send http requests and get its results back in a single line of code
It is super, light weight- but very dynamic. It uses an inline builder style syntax to keep your code super clean.

It is written in swift and uses the most recent ios networking api, NSURLSession.

DESC
s.homepage         = "https://github.com/logansease/QwikHttp"
# s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
s.license          = 'MIT'
s.author           = { "Logan Sease" => "lsease@gmail.com" }
s.source           = { :git => "https://github.com/logansease/QwikHttp.git", :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/logansease'


s.tvos.deployment_target = '9.0'
s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.9'
s.watchos.deployment_target = '2.0'
s.requires_arc = true

  s.source_files = 'QwikHttp/Classes/**/*'
  s.dependency 'QwikJson'

end
