Pod::Spec.new do |s|
  s.name     = 'TOScrollBar'
  s.version  = '0.0.5'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'An interactive scroll bar for to easily traverse comically massive scroll views.'
  s.homepage = 'https://github.com/TimOliver/TOScrollBar'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOScrollBar.git', :tag => s.version }
  s.platform = :ios, '7.0'
  s.source_files = 'TOScrollBar/**/*.{h,m}'
  s.requires_arc = true
end
