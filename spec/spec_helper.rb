# frozen_string_literal: true

require 'rspec'

ROOT = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.join(ROOT, 'lib'))

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  # Browser specs boot Chrome and load 115 pages; opt in with BROWSER=1.
  config.filter_run_excluding(:browser) unless ENV['BROWSER']
end
