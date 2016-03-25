Pod::Spec.new do |s|

  s.name         = "PHFetchedResultsController"
  s.version      = "2.0.0"
  s.summary      = "A fetchedResultsController for PhotoKit. It can be divided into sections by date PhotoKit"
  s.homepage     = "https://github.com/1amageek/PHFetchedResultsController"
  #s.screenshots	 = ""
  s.license      = { :type => "MIT" }
  s.author       = { "1_am_a_geek" => "tmy0x3@icloud.com" }
  s.social_media_url   = "http://twitter.com/1_am_a_geek"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/1amageek/PHFetchedResultsController.git", :tag => "#{s.version}" }
  s.source_files  = ["PHFetchedResultsController/PHFetchedResultsController.{h,m}"]

end
