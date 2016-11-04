module GraphQL::Relay::Walker
  module ClientExt
    # Walk this client's graph from the given GID.
    #
    # from_id: - The String GID to start walking from.
    # variables: - A Hash of variables to be passed to GraphQL::Client.
    # context: - A Hash containing context to be passed to GraphQL::Client.
    # &blk     - A block to call with each Walker::Frame that is visited.
    #
    # Returns nothing.
    def walk(from_id:, variables: {}, context: {})
      query_string = GraphQL::Relay::Walker.query_string(schema)
      walker_query = parse(query_string)

      GraphQL::Relay::Walker.walk(from_id: from_id) do |frame|
        response = query(
          walker_query,
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

begin
  require "graphql/relay/walker"
  require "graphql/client"
  GraphQL::Client.send(:include, GraphQL::Relay::Walker::ClientExt)
rescue LoadError
end
