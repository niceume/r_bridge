require_relative 'lib/r_bridge/version'

Gem::Specification.new do |spec|
  spec.name          = "r_bridge"
  spec.version       = RBridge::VERSION
  spec.authors       = ["Toshihiro Umehara"]
  spec.email         = ["toshi@niceume.com"]

  spec.summary       = %q{Enables Ruby to construct and evaluate R internal objects}
  spec.description   = %q{R (language) provides C interface. This package utilize the interface and allow Ruby to construct and evaluate R's internal S expressions }
  spec.homepage      = "https://github.com/niceume/r_bridge"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

#  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.extensions = %w[ext/r_bridge/extconf.rb]
  spec.add_dependency "ffi" , '~> 1.13', '>= 1.13.0'
end
