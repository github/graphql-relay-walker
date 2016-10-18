Gem::Specification.new do |s|
  s.name        = "graphql-relay-walker"
  s.version     = "0.0.2"
  s.licenses    = ["MIT"]
  s.summary     = "Traverse a Relay GraphQL graph"
  s.authors     = ["Ben Toews"]
  s.email       = "opensource+graphql-relay-walker@github.com"
  s.files       = %w(LICENSE.md README.md CONTRIBUTING.md CODE_OF_CONDUCT.md graphql-relay-walker.gemspec)
  s.files       += Dir.glob("lib/**/*.rb")
  s.homepage    = "https://github.com/github/graphql-relay-walker"

  s.add_dependency "graphql", "~> 0.19"
end
