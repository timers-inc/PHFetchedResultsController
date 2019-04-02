Pod::Spec.new do |s|

  s.name         = "PHFetchedResultsController"
  s.version      = "2.2.4"
  s.summary      = "A fetchedResultsController for PhotoKit. It can be divided into sections by date PhotoKit"
  s.homepage     = "https://github.com/timers-inc/PHFetchedResultsController"
  #s.screenshots	 = ""
  s.license      = { :type => "MIT" }
  s.author       = { "timers-ios" => "sys-info+ios@timers-inc.com" }
  s.social_media_url   = "http://twitter.com/Timers_inc"
  s.platform     = :ios, "8.0"
  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/timers-inc/PHFetchedResultsController.git", :tag => "#{s.version}" }
  s.source_files  = ["PHFetchedResultsController/PHFetchedResultsController.{h,m}"]

end
