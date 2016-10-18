module GraphQL::Relay::Walker
  class Queue
    attr_accessor :max_size, :random_idx

    # Initialize a new Queue.
    #
    # max_size:   - The maximum size the queue can grow to. This helps when
    #               walking a large graph by forcing us to walk deeper.
    # random_idx: - Add frames to the queue at random indicies. This helps when
    #               walking a large graph by forcing us to walk deeper.
    #
    # Returns nothing.
    def initialize(max_size: nil, random_idx: false)
      @max_size = max_size
      @random_idx = random_idx

      @queue = []
      @seen = Set.new
    end

    # Add a frame to the queue if its GID hasn't been seen already and the queue
    # hasn't exceeded its max size.
    #
    # frame - The Queue::Frame to add to the queue.
    #
    # Returns true if the frame was added, false otherwise.
    def add(frame)
      return false if max_size && queue.length >= max_size
      return false if @seen.include?(frame.gid)

      @seen.add(frame.gid)
      idx = random_idx ? rand(@queue.length + 1) : @queue.length
      @queue.insert(idx, frame)

      true
    end

    # Add a GID to the queue.
    #
    # gid    - The String GID to add to the queue.
    # parent - The frame where this GID was discovered (optional).
    #
    # Returns true if a frame was added, false otherwise.
    def add_gid(gid, parent=nil)
      frame = Frame.new(self, gid, parent)
      add(frame)
    end

    # Iterate through the queue, yielding each frame.
    #
    # Returns nothing.
    def each_frame
      while frame = @queue.shift
        yield(frame)
      end
    end
  end

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
    # Returns a Queue::Frame instance.
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
