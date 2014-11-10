require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'

$:.push File.expand_path(File.join("..", "..", "libraries"), __FILE__)

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__), "support", "**", "*.rb"))].each { |file| require file }
