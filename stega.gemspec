# frozen_string_literal: true

require_relative "lib/stega/version"

Gem::Specification.new do |s|
  s.name = "stega"
  s.version = Stega::VERSION
  s.authors = ["Theodor Tonum"]
  s.email = ["theodor@tonum.no"]
  s.homepage = "https://github.com/rorkjop/stega"
  s.summary = "Steganographic encoding and decoding for strings"
  s.description = "A Ruby implementation of Vercel's stega encoding for embedding invisible data in strings, with Sanity source map support."

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/rorkjop/stega/issues",
    "changelog_uri" => "https://github.com/rorkjop/stega/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/rorkjop/stega",
    "homepage_uri" => "https://github.com/rorkjop/stega",
    "source_code_uri" => "https://github.com/rorkjop/stega",
    "rubygems_mfa_required" => "true"
  }

  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 3.2"

  s.add_development_dependency "bundler", ">= 1.15"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.9"

end
