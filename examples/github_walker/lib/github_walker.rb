require "graphql/client"
require "graphql/client/http"

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

  WalkerQuery = GraphQL::Relay::Walker.schema_query(Client)

  def self.walk(&blk)
    gid = Client.query(ViewerIdQuery).data.viewer.id
    GraphQL::Relay::Walker.client_walk(client: Client, query: WalkerQuery, from_id: gid, &blk)
  end
end
