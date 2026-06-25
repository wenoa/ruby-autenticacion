require "simplecov"
require "simplecov-console"

if ENV["COVERAGE"]
  SimpleCov.start {
    enable_coverage :branch
  }
end

require "webmock/rspec"

require_relative "../lib/autenticacion"
require_relative "../lib/autenticacion/integraciones/roda"
