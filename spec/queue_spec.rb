require 'graphql/relay/walker'
require 'securerandom'

describe GraphQL::Relay::Walker::Queue do
  describe 'add' do
    let(:frame_one) { new_frame }
    let(:frame_two) { new_frame }

    it 'adds a frame to the queue' do
      subject.add(frame_one)
      expect(subject.queue.last).to eq(frame_one)
    end

    it 'adds frames to the end' do
      subject.add(frame_one)
      subject.add(frame_two)

      expect(subject.queue.first).to eq(frame_one)
      expect(subject.queue.last).to eq(frame_two)
    end

    it "doesn't add duplicate frames" do
      subject.add(frame_one)
      subject.add(frame_one)
      subject.add(new_frame(frame_one.gid))
      expect(subject.queue.size).to eq(1)
    end

    it 'can add frames at random indicies' do
      subject.random_idx = true

      frames = (1..10).map do |gid|
        new_frame(gid).tap { |frame| subject.add(frame) }
      end

      expect(subject.queue).not_to eq(frames)
      expect(subject.queue.sort_by(&:gid)).to eq(frames)
    end

    it 'can enforce a max size' do
      subject.max_size = 5

      frames = (1..10).map do |gid|
        new_frame(gid).tap { |frame| subject.add(frame) }
      end

      expect(subject.queue).to eq(frames[0...5])
    end

    it 'returns true if the frame is added' do
      expect(subject.add(frame_one)).to be(true)
      expect(subject.add(frame_two)).to be(true)
    end

    it 'returns false for duplicate GIDs' do
      duplicate = new_frame(frame_one.gid)
      expect(subject.add(frame_one)).to be(true)
      expect(subject.add(duplicate)).to be(false)
    end

    it 'returns false if the max size is exceeded' do
      subject.max_size = 2

      expect(subject.add(new_frame)).to be(true)
      expect(subject.add(new_frame)).to be(true)
      expect(subject.add(new_frame)).to be(false)
      expect(subject.add(new_frame)).to be(false)
    end
  end

  describe 'add_gid' do
    let(:gid) { new_gid }

    it 'makes a frame and adds it to the queue' do
      parent = new_frame
      subject.add_gid(gid, parent)
      frame = subject.queue.last

      expect(frame.gid).to eq(gid)
      expect(frame.parent).to eq(parent)
    end
  end

  describe 'each_frame' do
    let(:frames) { (1..10).map { new_frame } }

    before do
      frames.each { |frame| subject.add(frame) }
    end

    it 'returns an enumerator unless a block is given' do
      expect(subject.each_frame.to_a).to eq(frames)
    end

    it 'yields each frame' do
      yielded = []
      subject.each_frame { |frame| yielded << frame }
      expect(yielded).to eq(frames)
    end
  end

  def new_gid
    SecureRandom.hex
  end

  def new_frame(gid = new_gid, parent = nil)
    GraphQL::Relay::Walker::Frame.new(subject, gid, parent)
  end
end
