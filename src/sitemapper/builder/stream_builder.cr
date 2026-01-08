require "../builder"

module Sitemapper
  # This class builds sitemap files one at a time, saving each as it reaches
  # the limit of `@max_urls`. Callers don't need to call `Sitemapper.store`
  # afterwards.
  class StreamBuilder < Builder
    getter paginator : Paginator

    def initialize(@host : String, @max_urls : Int32, @use_index : Bool, @storage : Sitemapper::Storage.class, @storage_path : String)
      @paginator = Paginator.new(limit: @max_urls)
      @filenames = [] of String
      @current_page = 1
    end

    def add(path, **kwargs) : self
      options = SitemapOptions.new(**kwargs)
      paginator.add(path, options)
      if paginator.paths.size.modulo(@max_urls).zero?
        flush
      end
      self
    end

    def flush
      page = @current_page
      filename = filename_for_current_page
      doc = build_xml_for_page(paginator.items(1))
      @filenames << filename

      storage = @storage.new([{"name" => filename, "data" => doc}])
      storage.save(@storage_path)

      @current_page += 1
      @paginator = Paginator.new(limit: @max_urls)
    end

    def finish : Void
      unless paginator.paths.empty?
        flush
      end

      if @use_index
        save_index
      end
    end

    private def save_index : Void
      index = generate_index(@filenames)
      storage = @storage.new([index])
      storage.save(@storage_path)
    end

    private def filename_for_current_page
      "sitemap#{@current_page}.xml"
    end
  end
end
