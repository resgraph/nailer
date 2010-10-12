require 'monitor'

module Nailer

  class SynchronizedBuffer < Monitor

    attr_reader :capacity

    def initialize(capacity)
      raise ArgumentError if capacity == 0
      @capacity = capacity
      @front = 0
      @back = 0
      @elements = Array.new(capacity)
      @empty_cond = new_cond
      @full_cond = new_cond
      super()
    end

    def get
      synchronize do
        @empty_cond.wait_while { empty? }
        element = @elements[@front]
        @elements[@front] = nil
        @front = (@front + 1) % @capacity
        @full_cond.signal
        return element
      end
    end

    def put(element)
      synchronize do
        @full_cond.wait_while { full? }
        @elements[@back] = element
        @back = (@back + 1) % @capacity
        @empty_cond.signal
      end
    end

    def full?
      synchronize do
        (@front == @back and @elements[@front] != nil)
      end
    end

    def empty?
      synchronize do
        (@front == @back and @elements[@front] == nil)
      end
    end

  end

  def after_create
    begin
      self.create_resource_click_count
      Resque.enqueue(Resource, self.id)
    rescue => err
      logger.error("Error - resource.after_create #{self.id.to_s}: #{err}")
    end
  end

  def self.perform(id)
    find(id).try(:generate_thumbnail)
  end

  def generate_thumbnail
    SystemTimer.timeout_after(30.seconds) do
      tn = ThumbNailer.new(url, id)
      tn.create_thumbnails
      tn.associate_resource_with_preview
    end
  end

  def preview_url(style)
    unless self.preview.exists?
      begin
        Resque.enqueue(Resource, self.id)
      rescue => err
        logger.error("Error - resource.preview_url #{self.id.to_s}: #{err}")
      end
    end
    self.preview.url(style)
  end

end