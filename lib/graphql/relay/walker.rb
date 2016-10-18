require "graphql"

module GraphQL::Relay
  module Walker
    # Build a query that starts with a relay node and grabs the IDs of all its
    # connections and node fields.
    #
    # schema - The GraphQL::Schema to build a query for.
    #
    # Returns a String query.
    def self.query_string(schema)
      QueryBuilder.new(schema).query_string
    end

    # Start traversing a graph, starting from the given relay node ID.
    #
    # from_id: - The `ID!` id to start walking from.
    # &blk     - A block to call with each Walker::Frame that is visited.
    #            This block is responsible for executing a query for the frame's
    #            GID, storing the results in the frame, and enqueuing further
    #            node IDs to visit.
    #
    # Returns nothing.
    def self.walk(from_id:, &blk)
      queue = Queue.new
      queue.add_gid(from_id)
      queue.each_frame(&blk)
    end

  end
end

require "graphql/relay/walker/queue"
require "graphql/relay/walker/frame"
require "graphql/relay/walker/query_builder"
