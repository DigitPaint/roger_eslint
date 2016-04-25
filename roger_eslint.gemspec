# -*- encoding: utf-8 -*-

require File.dirname(__FILE__) + "/lib/roger_eslint/version"

Gem::Specification.new do |s|
  s.authors = ["Flurin Egger"]
  s.email = ["info@digitpaint.nl", "flurin@digitpaint.nl"]
  s.name = "roger_eslint"
  s.version = RogerEslint::VERSION
  s.homepage = "https://github.com/digitpaint/roger_eslint"

  s.summary = "Lint JavaScript files with ESLint within Roger"
  s.description = <<-EOF
    Lint JavaScript files from within Roger, using eslint.
    Will use .eslintrc.
  EOF
  s.licenses = ["MIT"]

  s.date = Time.now.strftime("%Y-%m-%d")

  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "roger", "~> 1.4", ">= 1.0.0"

  s.add_development_dependency "rubocop", [">= 0"]
  s.add_development_dependency "rake", [">= 0"]
  s.add_development_dependency "test-unit", [">= 0"]
  s.add_development_dependency "thor", ["~> 0"]
  s.add_development_dependency "mocha", ["~> 1.1.0"]
end
