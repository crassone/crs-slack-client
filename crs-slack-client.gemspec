# frozen_string_literal: true

require_relative "lib/crs/slack/client/version"

Gem::Specification.new do |spec|
  spec.name = "crs-slack-client"
  spec.version = Crs::Slack::Client::VERSION
  spec.authors = ["jacoyutorius"]
  spec.email = ["yuto_ogi@crassone.jp"]

  spec.summary = "Slack API Client for Crassone"
  spec.description = "A Ruby client for the Slack API, designed for use with Crassone."
  spec.homepage = "https://github.com/crassone/crs-slack-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile]) ||
        f.end_with?(".gem")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.23.1"
  spec.add_dependency "mime-types", "~> 3.7"
  spec.add_dependency "multipart-post", "~> 2.4"
  spec.add_dependency "ostruct", "~> 0.1.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
