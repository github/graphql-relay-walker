module GraphQL::Relay::Walker
  class Frame
    attr_reader :queue, :gid, :parent, :context
    attr_accessor :result

    # Initialize a new Frame.
    #
    # queue  - The Queue that this frame belongs to.
    # gid    - The String GID.
    # parent - The Frame where this GID was discovered.
    #
    # Returns nothing.
    def initialize(queue, gid, parent)
      @queue   = queue
      @gid     = gid
      @parent  = parent
      @context = {}
    end

    # Add each found GID to the queue.
    #
    # Returns nothing.
    def enqueue_found_gids
      found_gids.each { |gid| queue.add(child(gid)) }
    end

    # Make a new frame with the given GID and this frame as its parent.
    #
    # gid - The String GID to create the frame with.
    #
    # Returns a Frame instance.
    def child(gid)
      Frame.new(queue, gid, self)
    end

    # The GIDs from this frame's results.
    #
    # Returns an Array of GID Strings.
    def found_gids(data=result)
      [].tap do |ids|
        case data
        when Hash
          ids.concat(Array(data["id"]))
          ids.concat(found_gids(data.values))
        when Array
          data.each { |datum| ids.concat(found_gids(datum)) }
        end
      end
    end
  end
end
