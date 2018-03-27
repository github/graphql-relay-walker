module GraphQL::Relay::Walker
  class Queue
    attr_accessor :max_size, :random_idx
    attr_reader   :queue, :seen

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
    # frame - The Frame to add to the queue.
    #
    # Returns true if the frame was added, false otherwise.
    def add(frame)
      return false if max_size && queue.length >= max_size
      return false if seen.include?(frame.gid)

      seen.add(frame.gid)
      idx = random_idx ? rand(queue.length + 1) : queue.length
      queue.insert(idx, frame)

      true
    end

    # Add a GID to the queue.
    #
    # gid    - The String GID to add to the queue.
    # parent - The frame where this GID was discovered (optional).
    #
    # Returns true if a frame was added, false otherwise.
    def add_gid(gid, parent = nil)
      frame = Frame.new(self, gid, parent)
      add(frame)
    end

    # Iterate through the queue, yielding each frame.
    #
    # Returns nothing.
    def each_frame
      return enum_for(:each_frame) unless block_given?

      while frame = queue.shift
        yield(frame)
      end
    end
  end
end
