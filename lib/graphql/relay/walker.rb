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

    def self.schema_query(client)
      client.parse(query_string(client.schema))
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

    # Walk this client's graph from the given GID.
    #
    # from_id: - The String GID to start walking from.
    # variables: - A Hash of variables to be passed to GraphQL::Client.
    # context: - A Hash containing context to be passed to GraphQL::Client.
    # &blk     - A block to call with each Walker::Frame that is visited.
    #
    # Returns nothing.
    def self.client_walk(client:, query:, from_id:, variables: {}, context: {})
      walk(from_id: from_id) do |frame|
        response = client.query(
          query,
          variables: variables.merge({"id" => frame.gid}),
          context: context
        )

        frame.context[:response] = response
        frame.result = (response.respond_to?(:data) && response.data) ? response.data.to_h : {}
        frame.enqueue_found_gids

        yield(frame) if block_given?
      end
    end
  end
end

require "graphql/relay/walker/queue"
require "graphql/relay/walker/frame"
require "graphql/relay/walker/query_builder"
