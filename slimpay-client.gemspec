$:.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'slimpay-client'
  s.summary = "Ruby library for Slimpay"
  s.description = s.summary
  s.homepage = "https://github.com/jonathantribouharet/slimpay-client"
  s.version = '1.0.3'
  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
  s.authors = ['Jonathan VUKOVICH TRIBOUHARET']
  s.email = 'jonathan.tribouharet@gmail.com'
  s.license = 'MIT'
  s.platform = Gem::Platform::RUBY

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'multi_json'
  s.add_dependency 'oauth2', '>= 0.9.0'
end
