module Sitemapper
  abstract class Builder
    XMLNS_SCHEMA       = "http://www.sitemaps.org/schemas/sitemap/0.9"
    XMLNS_VIDEO_SCHEMA = "http://www.google.com/schemas/sitemap-video/1.1"
    XMLNS_IMAGE_SCHEMA = "http://www.google.com/schemas/sitemap-image/1.1"
    # See: https://sitemaps.org/protocol.html#validating
    XMLNS_XSI                 = "http://www.w3.org/2001/XMLSchema-instance"
    XSI_SCHEMA_LOCATION       = "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd"
    XSI_INDEX_SCHEMA_LOCATION = "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd"

    abstract def add(path, **kwargs) : self

    private def build_xml_for_page(items)
      XML.build(indent: " ") do |xml|
        xml.element("urlset", xmlns: XMLNS_SCHEMA, "xmlns:video": XMLNS_VIDEO_SCHEMA, "xmlns:image": XMLNS_IMAGE_SCHEMA, "xmlns:xsi": XMLNS_XSI, "xsi:schemaLocation": XSI_SCHEMA_LOCATION) do
          items.each do |info|
            build_xml_from_info(xml, info)
          end
        end
      end
    end

    private def build_xml_from_info(xml, info)
      path = info[0].as(String)
      options = info[1].as(SitemapOptions)

      xml.element("url") do
        xml.element("loc") { xml.text [@host, path].join }
        xml.element("lastmod") { xml.text options.lastmod.as(Time).to_s("%FT%X%:z") }
        xml.element("changefreq") { xml.text options.changefreq.to_s }
        xml.element("priority") { xml.text options.priority.to_s }
        unless options.video.nil?
          options.video.as(VideoMap).render_xml(xml)
        end
        unless options.image.nil?
          options.image.as(ImageMap).render_xml(xml)
        end
      end
    end

    private def generate_index(filenames : Array(String)) : Hash(String, String)
      doc = XML.build(indent: " ") do |xml|
        xml.element("sitemapindex", xmlns: XMLNS_SCHEMA, "xmlns:video": XMLNS_VIDEO_SCHEMA, "xmlns:image": XMLNS_IMAGE_SCHEMA, "xmlns:xsi": XMLNS_XSI, "xsi:schemaLocation": XSI_INDEX_SCHEMA_LOCATION) do
          filenames.each do |filename|
            xml.element("sitemap") do
              sitemap_name = filename + (Sitemapper.config.compress ? ".gz" : "")
              sitemap_url = [(Sitemapper.config.sitemap_host || @host), sitemap_name].join('/')

              xml.element("loc") { xml.text sitemap_url }
              xml.element("lastmod") { xml.text Time.utc.to_s("%FT%X%:z") }
            end
          end
        end
      end
      filename = "sitemap_index.xml"
      {"name" => filename, "data" => doc}
    end
  end
end
