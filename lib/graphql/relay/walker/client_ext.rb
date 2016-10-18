module GraphQL::Relay::Walker
  module ClientExt
    # Walk this client's graph from the given GID.
    #
    # from_id: - The String GID to start walking from.
    # &blk     - A block to call with each Walker::Frame that is visited.
    #
    # Returns nothing.
    def walk(from_id:)
      query_string = GraphQL::Relay::Walker.query_string(schema)
      walker_query = parse(query_string)

      GraphQL::Relay::Walker.walk(from_id: from_id) do |frame|
        response = query(walker_query, variables: {"id" => frame.gid})
        frame.context[:response] = response
        frame.result = response.data.to_h
        frame.enqueue_found_gids
        yield(frame) if block_given?
      end
    end
  end
end

begin
  require "graphql/relay/walker"
  require "graphql/client"
  GraphQL::Client.send(:include, GraphQL::Relay::Walker::ClientExt)
rescue LoadError
end
