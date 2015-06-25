# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "straight"
  gem.homepage = "http://github.com/snitko/straight"
  gem.license = "MIT"
  gem.summary = %Q{An engine for the Straight payment gateway software}
  gem.description = %Q{An engine for the Straight payment gateway software. Requires no state to be saved (that is, no storage or DB). Its responsibilities only include processing data coming from an actual gateway.}
  gem.email = "roman.snitko@gmail.com"
  gem.authors = ["Roman Snitko"]
  gem.files.exclude 'spec/**/*'
end
Jeweler::RubygemsDotOrgTasks.new

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  # no rspec available
end
