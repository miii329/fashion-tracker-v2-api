require "open-uri"

class Brand < ApplicationRecord
  belongs_to :user
  has_one_attached :logo
  has_many_attached :images

  def attach_ogp_image_from_url(fetcher: OgpService, opener: URI)
    return if url.blank?

    image_url = fetcher.fetch_image(url)
    return if image_url.blank?

    update_column(:og_image_url, image_url) if og_image_url != image_url
    return if ogp_image_attached?(image_url)

    downloaded_image = opener.open(image_url)
    filename = image_filename(image_url)
    content_type = downloaded_image.content_type.presence || Marcel::MimeType.for(downloaded_image, name: filename)

    images.attach(
      io: downloaded_image,
      filename: filename,
      content_type: content_type,
      metadata: { source_url: image_url }
    )
  rescue OpenURI::HTTPError, SocketError, URI::InvalidURIError, Timeout::Error => error
    Rails.logger.warn("Brand##{id}: failed to attach OGP image - #{error.message}")
  ensure
    downloaded_image&.close if defined?(downloaded_image) && downloaded_image.respond_to?(:close)
  end

  private

  def ogp_image_attached?(image_url)
    images.blobs.any? { |blob| blob.metadata["source_url"] == image_url }
  end

  def image_filename(image_url)
    path = URI.parse(image_url).path
    filename = File.basename(path)
    filename.presence || "ogp-image-#{id}.jpg"
  rescue URI::InvalidURIError
    "ogp-image-#{id}.jpg"
  end
end
