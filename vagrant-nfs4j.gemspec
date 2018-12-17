
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vagrant-nfs4j/version"

Gem::Specification.new do |spec|
  spec.name          = "vagrant-nfs4j"
  spec.version       = VagrantNfs4j::VERSION
  spec.licenses      = ["Apache-2.0"]
  spec.authors       = ["Rémi Alvergnat"]
  spec.email         = ["toilal.dev@gmail.com"]

  spec.summary       = "Vagrant plugin for Vagrant NFS Synced Folders on Windows"
  spec.description   = <<-EOD
A vagrant plugin that brings support of Vagrant NFS Synced Folders to Windows with 
nfs4j-daemon under the hood.
  EOD
  spec.homepage      = "https://github.com/gfi-centre-ouest/vagrant-nfs4j"


  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/gfi-centre-ouest/vagrant-nfs4j"
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 12.3"
end
