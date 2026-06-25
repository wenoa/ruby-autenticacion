require_relative "lib/autenticacion/version"

Gem::Specification.new { |spec|
  spec.name = "autenticacion"
  spec.version = Autenticacion::VERSION
  spec.authors = ["Wenoa Studio"]
  spec.email = ["desarrollo@wenoa.studio"]

  spec.summary = "Autenticación de tokens con guardianes de estrategia intercambiable."
  spec.description = spec.summary
  spec.homepage = "https://github.com/wenoa/ruby-autenticacion"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64", ">= 0.2"
  spec.add_dependency "jwt", ">= 2.7"
}
