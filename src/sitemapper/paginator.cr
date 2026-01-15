module Sitemapper
  class Paginator
    DEFAULT_LIMIT = 500
    property paths : Array(Tuple(String, SitemapOptions))
    property index_paths : Array(String)

    def initialize(@limit : Int32 = DEFAULT_LIMIT)
      @paths = [] of Tuple(String, SitemapOptions)
      @index_paths = [] of String
    end

    def add(path : String, options : SitemapOptions)
      @paths << {path, options}
    end

    def index_add(path : String)
      Log.info{"index_add paginator path:"}
      Log.info{path}
      @index_paths << path
      Log.info{"index_add paginator result:"}
      Log.info{@index_paths}
    end

    def items(current_page : Int32)
      offset = (current_page * @limit) - @limit
      @paths[offset, @limit]
    end

    def index_items
      @index_paths
    end

    # This is calculated each time since you could
    # get 1 the first time, then add to it and get 2 the second
    def total_pages
      (@paths.size / @limit.to_f).ceil.to_i
    end
  end
end
