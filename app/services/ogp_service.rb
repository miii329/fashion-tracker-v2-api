require "metainspector"
require "open-uri"
require "net/http"
require "json"
require "erb"
require "nokogiri"

class OgpService
  USER_AGENT = "facebookexternalhit/1.1".freeze
  BROWSER_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".freeze

  def self.fetch_all(url)
    product_data = fetch_product_data_from_json_ld(url)
    iframely_data = fetch_iframely_data(url)
    title = fetch_title(url)
    html = fetch_html_for_json_ld(url)

    product_name = product_data[:name] || title
    image_url = product_data[:image_url] || fetch_image(url)
    price = product_data[:price] || extract_price(iframely_data&.dig("meta", "price")) || extract_price_from_html(html)
    currency = product_data[:currency] || iframely_data&.dig("meta", "currency") || extract_currency_from_html(html)

    {
      url: url,
      item_name: product_name,
      name: product_name,
      title: title,
      image_url: image_url,
      price: price,
      currency: currency
    }
  end

  def self.fetch_image(url)
    options = {
      connection_options: {
        headers: { "User-Agent" => USER_AGENT }
      }
    }

    page = MetaInspector.new(url, options)
    image = page.images.best
    return image if image.present?

    fetch_from_iframely(url)
  rescue MetaInspector::Error, OpenURI::HTTPError, SocketError, Timeout::Error => error
    Rails.logger.warn("OgpService: MetaInspector failed: #{error.message}. Fallback to Iframely.")
    fetch_from_iframely(url)
  end

  def self.fetch_from_iframely(url)
    api_key = ENV["IFRAMELY_API_KEY"]
    return nil if api_key.blank?

    encoded_url = ERB::Util.url_encode(url)
    api_url = "https://iframe.ly/api/iframely?url=#{encoded_url}&api_key=#{api_key}"

    response = Net::HTTP.get(URI(api_url))
    data = JSON.parse(response)

    data.dig("links", "thumbnail", 0, "href") || data.dig("og", "image")
  rescue JSON::ParserError, SocketError, Timeout::Error => error
    Rails.logger.warn("OgpService: Iframely failed: #{error.message}")
    nil
  end

  def self.fetch_product_name(url)
    product_name = fetch_product_data_from_json_ld(url)[:name]
    return product_name if product_name.present?

    fetch_title(url)
  end

  def self.fetch_title(url)
    options = {
      connection_options: {
        headers: { "User-Agent" => USER_AGENT }
      }
    }

    page = MetaInspector.new(url, options)
    title = page.best_title
    return title if title.present? && title != "Access Denied"

    data = fetch_iframely_data(url)
    data&.dig("meta", "title") || data&.dig("og", "title") || data&.dig("title")
  rescue MetaInspector::Error, OpenURI::HTTPError, SocketError, Timeout::Error => error
    Rails.logger.warn("OgpService: title fetch failed: #{error.message}")
    data = fetch_iframely_data(url)
    data&.dig("meta", "title") || data&.dig("og", "title") || data&.dig("title")
  end

  def self.fetch_iframely_data(url)
    api_key = ENV["IFRAMELY_API_KEY"]
    return nil if api_key.blank?

    encoded_url = ERB::Util.url_encode(url)
    api_url = "https://iframe.ly/api/iframely?url=#{encoded_url}&api_key=#{api_key}"

    response = Net::HTTP.get(URI(api_url))
    JSON.parse(response)
  rescue JSON::ParserError, SocketError, Timeout::Error => error
    Rails.logger.warn("OgpService: Iframely data fetch failed: #{error.message}")
    nil
  end

  def self.fetch_product_name_from_json_ld(url)
    fetch_product_data_from_json_ld(url)[:name]
  end

  def self.fetch_product_data_from_json_ld(url)
    html = fetch_html_for_json_ld(url)
    return {} if html.blank?

    document = Nokogiri::HTML(html)
    scripts = document.css('script[type="application/ld+json"]')

    scripts.each do |script|
      begin
        data = JSON.parse(script.text)
      rescue JSON::ParserError
        next
      end

      product_data = extract_product_data_from_json_ld(data)
      return product_data if product_data.present?
    end

    {}
  rescue OpenURI::HTTPError, SocketError, Timeout::Error, URI::InvalidURIError => error
    Rails.logger.warn("OgpService: JSON-LD fetch failed: #{error.message}")
    {}
  end

  def self.extract_product_data_from_json_ld(data)
    case data
    when Array
      data.each do |node|
        result = extract_product_data_from_json_ld(node)
        return result if result.present?
      end
      nil
    when Hash
      extracted = {}

      if data["@graph"].is_a?(Array)
        result = extract_product_data_from_json_ld(data["@graph"])
        extracted.merge!(result) if result.present?
      end

      type = data["@type"]
      types = type.is_a?(Array) ? type : [ type ]
      if types.compact.any? { |t| t.to_s.downcase.include?("product") }
        result = {
          name: data["name"].presence,
          image_url: extract_image_url(data["image"]),
          price: extract_price(data["offers"]),
          currency: extract_currency(data["offers"])
        }.compact
        extracted.merge!(result) if result.present?
      end

      data.each_value do |value|
        next unless value.is_a?(Array) || value.is_a?(Hash)

        result = extract_product_data_from_json_ld(value)
        extracted.merge!(result) if result.present?
      end

      extracted.presence
    else
      nil
    end
  end

  def self.extract_product_name_from_json_ld(data)
    extract_product_data_from_json_ld(data)&.dig(:name)
  end

  def self.extract_image_url(image_value)
    case image_value
    when String
      image_value
    when Array
      image_value.find(&:present?)
    when Hash
      image_value["url"] || image_value["@id"]
    else
      nil
    end
  end

  def self.extract_price(offers_value)
    if offers_value.is_a?(String) || offers_value.is_a?(Numeric)
      price = offers_value.to_s.gsub(/[^0-9.]/, "")
      return nil if price.blank?

      return price.to_f.round
    end

    offers = case offers_value
    when Array
      offers_value.first
    else
      offers_value
    end

    return nil unless offers.is_a?(Hash)

    raw_price = offers["price"] || offers["lowPrice"]
    return nil if raw_price.blank?

    price = raw_price.to_s.gsub(/[^0-9.]/, "")
    return nil if price.blank?

    price.to_f.round
  end

  def self.extract_currency(offers_value)
    offers = case offers_value
    when Array
      offers_value.first
    else
      offers_value
    end

    return nil unless offers.is_a?(Hash)

    offers["priceCurrency"] || offers["currency"]
  end

  def self.extract_price_from_html(html)
    return nil if html.blank?

    patterns = [
      /["']price["']\s*[:=]\s*["']?(?<price>\d+(?:\.\d+)?)["']?/i,
      /(?:¥|￥)\s*(?<price>\d[\d,]*(?:\.\d+)?)/,
      /(?<price>\d+(?:\.\d+)?)\s*JPY/i
    ]

    patterns.each do |pattern|
      match = html.match(pattern)
      next unless match

      parsed = extract_price(match[:price])
      return parsed if parsed.present?
    end

    nil
  end

  def self.extract_currency_from_html(html)
    return nil if html.blank?

    match = html.match(/["'](?:priceCurrency|currency)["']\s*[:=]\s*["'](?<currency>[A-Z]{3})["']/i)
    return match[:currency].upcase if match

    return "JPY" if html.match?(/(?:¥|￥|JPY)/i)

    nil
  end

  def self.fetch_html_for_json_ld(url)
    [BROWSER_USER_AGENT, USER_AGENT].each do |agent|
      begin
        return URI.open(url, "User-Agent" => agent, "Accept-Language" => "ja-JP,ja;q=0.9,en;q=0.8").read
      rescue OpenURI::HTTPError, SocketError, Timeout::Error, URI::InvalidURIError => error
        Rails.logger.warn("OgpService: JSON-LD HTML fetch failed with UA #{agent}: #{error.message}")
      end
    end

    nil
  end

  def self.extract_product_name_from_json_ld_legacy(data)
    case data
    when Array
      data.each do |node|
        result = extract_product_name_from_json_ld_legacy(node)
        return result if result.present?
      end
      nil
    when Hash
      if data["@graph"].is_a?(Array)
        result = extract_product_name_from_json_ld_legacy(data["@graph"])
        return result if result.present?
      end

      type = data["@type"]
      types = type.is_a?(Array) ? type : [ type ]
      if types.compact.any? { |t| t.to_s.downcase.include?("product") }
        name = data["name"]
        return name if name.present?
      end

      data.each_value do |value|
        next unless value.is_a?(Array) || value.is_a?(Hash)

        result = extract_product_name_from_json_ld_legacy(value)
        return result if result.present?
      end

      nil
    else
      nil
    end
  end

  private_class_method :fetch_from_iframely,
                       :fetch_product_name_from_json_ld,
                       :fetch_product_data_from_json_ld,
                       :extract_product_data_from_json_ld,
                       :extract_image_url,
                       :extract_price,
                       :extract_currency,
                       :extract_price_from_html,
                       :extract_currency_from_html,
                       :fetch_iframely_data,
                       :fetch_html_for_json_ld,
                       :extract_product_name_from_json_ld,
                       :extract_product_name_from_json_ld_legacy
end
