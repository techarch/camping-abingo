require 'rubygems' 

SPEC = Gem::Specification.new do |s| 
  s.name = "camping-abingo" 
  s.version = "1.0.8" 
  
  s.authors = [ "Patrick McKenzie", "Philippe F. Monnet" ]
  s.email = ["patrick@kalzumeus.com", "techarch@monnet-usa.com"]
  s.date = %q{2012-11-23}
  s.homepage = "https://github.com/techarch/camping-abingo" 
  s.platform = Gem::Platform::RUBY 
  s.summary = "A plugin to add A/B testing capabilities using the ABingo framework to a Camping application" 
  s.description = <<-EOF
This is an ABingo plugin for the Ruby Camping framework, inspired by Patrick McKenzie's ABingo A/B testing Rails plugin (see http://www.bingocardcreator.com/abingo). 
  EOF
  s.rubyforge_project = "camping-abingo"
  
  s.add_dependency('activesupport')
  s.add_dependency('activerecord')
  s.add_dependency('rack')
  s.add_dependency('markaby')
  s.add_dependency('camping', '>= 2.0')
  s.add_dependency('filtering_camping', '>= 1.0')
  
  candidates = Dir.glob("{bin,doc,examples,lib,test}/**/*") 
  s.files = candidates.delete_if do |item| 
    item.include?("git") || item.include?("rdoc") 
  end 
  
  s.require_path = "lib" 
  s.autorequire = "camping-abingo" 
  #s.test_file = "test/test_camping-abingo.rb" 
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README"] 
end 
