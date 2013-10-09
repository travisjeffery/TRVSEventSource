Pod::Spec.new do |s|
  s.name         = "TRVSEventSource"
  s.version      = "0.0.1"
  s.summary      = "Server-sent events EventSource client using NSURLSession"
  s.homepage     = "http://github.com/travisjeffery/TRVSEventSource"
  s.license      = 'MIT'
  s.author       = { "Travis Jeffery" => "tj@travisjeffery.com" }
  s.platform     = :ios, '7.0'
  s.source       = { :git => "http://github.com/travisjeffery/TRVSEventSource.git", :tag => "0.0.1" }
  s.source_files  = 'TRVSEventSource', 'TRVSEventSource/**/*.{h,m}'
  s.requires_arc = true
end
