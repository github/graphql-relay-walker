require "graphql/client"
require "graphql/client/http"
require "graphql/relay/walker/client_ext"

module GitHubWalker
  URL = "https://api.github.com/graphql"

  TOKEN = ENV["GITHUB_ACCESS_TOKEN"]

  HTTP = GraphQL::Client::HTTP.new(URL) do
    def headers(context)
      {"Authorization" => "Bearer #{TOKEN}"}
    end
  end

  Schema = GraphQL::Client.load_schema(HTTP)

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  ViewerIdQuery = Client.parse <<-'GRAPHQL'
    query {
      viewer {
        id
      }
    }
  GRAPHQL

  def self.walk(&blk)
    gid = Client.query(ViewerIdQuery).data.viewer.id
    Client.walk(from_id: gid, &blk)
  end
end
