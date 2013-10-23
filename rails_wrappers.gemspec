$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_wrappers/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_wrappers"
  s.version     = RailsWrappers::VERSION
  s.authors     = ["Ivgeni Slabkovski"]
  s.email       = ["zhenya@zhenya.ca"]
  s.homepage    = "http://zhenya.ca"
  s.summary     = "Summary of RailsWrappers."
  s.description = "Description of RailsWrappers."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "activesupport", "~> 4.0.0"

  s.add_development_dependency "rails", "~> 4.0.0"
  s.add_development_dependency "sqlite3"
end
