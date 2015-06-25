require_relative "../lib/straight"
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr'
  config.hook_into :webmock
end

if ENV['VCR_OFF']
  WebMock.allow_net_connect!
  VCR.turn_off! ignore_cassettes: true
end
