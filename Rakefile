require "rspec/core/rake_task"
require "simplecov"
require "simplecov-console"

RSpec::Core::RakeTask.new(:spec)

task(:test) {
  FileUtils.rmtree("coverage")
  sh "COVERAGE=true rspec --format=documentation"
}

task(:format) { sh "rubocop -A" }

task(:check_coverage) {
  SimpleCov.collate(Dir["coverage/.resultset.json"]) {
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
    ])
  }
}

task default: [:format, :test, :check_coverage]
