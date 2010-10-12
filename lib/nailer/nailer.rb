module Nailer

  class Dimension
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
    end
  end

  class ThumbNailer
    include Simplificator::Webthumb

    @@api_baseurl = 'http://webthumb.bluga.net/api.php'
    @@api_key = '7c4fe46d3a748f15c69723fdf20568f0'
    @@user_id = '7194'
    @@thumbnail_dir = "#{RAILS_ROOT}/public/previews/"


    attr_accessor :url
    attr_accessor :id
    attr_accessor :large_size
    attr_accessor :file_name

    def initialize(url, id)
      @url = url
      @id = id
      @large_size = Dimension.new(1024, 768)
    end

    def determine_type
      url_type = 'html'
      case @url[/(pdf|ppt|doc|jpg|jpeg|gif|png)$/i]
        when 'pdf'
          url_type = 'image'
        when 'ppt'
          url_type = 'doc'
        when 'doc'
          url_type = 'doc'
        when 'jpg'
        when 'jpeg'
          url_type = 'image'
        when 'gif'
          url_type = 'image'
        when 'png'
          url_type = 'image'
      end
      url_type
    end

    def create_thumbnails(overwrite = false)
      ut = determine_type
      if ut == 'image'
        image_thumbnails(overwrite)
      elsif ut == 'html'
        site_thumbnails(overwrite)
      end
    end

    def associate_resource_with_preview
      begin
        resource = Resource.find(@id)
        fp = file_path("jpg")
        if !File.exists?(fp)
          fp = file_path("png")
        end
        if File.exists?(fp) && resource.preview_file_name.blank?
          file = File.new(fp, 'rb')
          resource.preview = file
          resource.save
          File.delete(fp)
        end
      rescue => err
        puts "ThumbNailer#associate_resource_with_preview: #{err.to_s}"
      end
    end

    protected

    def image_thumbnails(overwrite)
      begin
        fp = file_path("png")
        return if File.exist?(fp) && !overwrite
        image = Magick::ImageList.new(@url)
        if image
          thumb = image.scale(large_size.width, large_size.height)
          thumb.write fp
        end
      rescue => err
        puts "ThumbNailer#image_thumbnails: #{err.to_s}"
      end
    end

    def site_thumbnails(overwrite)
      begin
        fp = file_path("jpg")
        return if File.exists?(fp) && !overwrite
        wt = Webthumb.new(@@api_key)
        job = wt.thumbnail(:url => url)
        if job
          job.write_file(job.fetch_when_complete(:large), fp)
        end
      rescue => err
        puts "ThumbNailer#site_thumbnails: #{err.to_s}"
      end
    end

    def file_path(extension)
      begin
        dir_name = @@thumbnail_dir
        FileUtils.mkdir_p(dir_name)
        file_path = dir_name + "/#{@id.to_s}.#{extension}"
      rescue => err
        puts "Thumbnailer#file_path: #{err.to_s}"
      end
    end
  end



end