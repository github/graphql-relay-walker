source 'https://rubygems.org'

gemspec
if ENV["GRAPHQL_19"]
  puts "1.9-dev compatibility mode"
  gem "graphql", github: "rmosolgo/graphql-ruby", branch: "1.9-dev"
  gem "graphql-client", github: "github/graphql-client", branch: "support-1.9-dev"
end
