require "test_helper"
require "stringio"

class BrandTest < ActiveSupport::TestCase
  test "attach_ogp_image_from_url attaches image" do
    skip "Active Storage tables are not available" unless active_storage_tables_available?

    brand = brands(:one)
    image_url = "https://example.com/path/test-image.png"
    fake_image = StringIO.new("image-bytes")
    def fake_image.content_type
      "image/png"
    end

    fetcher = Struct.new(:image_url) do
      def fetch_image(_url)
        image_url
      end
    end.new(image_url)

    opener = Struct.new(:io) do
      def open(_url)
        io
      end
    end.new(fake_image)

    assert_difference("brand.images.attachments.count", 1) do
      brand.attach_ogp_image_from_url(fetcher: fetcher, opener: opener)
    end

    assert_equal image_url, brand.reload.og_image_url
    assert_equal image_url, brand.images.blobs.last.metadata["source_url"]
  end

  test "attach_ogp_image_from_url does not attach duplicate image" do
    skip "Active Storage tables are not available" unless active_storage_tables_available?

    brand = brands(:one)
    image_url = "https://example.com/path/test-image.png"

    first_image = StringIO.new("first-image")
    def first_image.content_type
      "image/png"
    end

    second_image = StringIO.new("second-image")
    def second_image.content_type
      "image/png"
    end

    fetcher = Struct.new(:image_url) do
      def fetch_image(_url)
        image_url
      end
    end.new(image_url)

    first_opener = Struct.new(:io) do
      def open(_url)
        io
      end
    end.new(first_image)

    second_opener = Struct.new(:io) do
      def open(_url)
        io
      end
    end.new(second_image)

    brand.attach_ogp_image_from_url(fetcher: fetcher, opener: first_opener)

    assert_no_difference("brand.images.attachments.count") do
      brand.attach_ogp_image_from_url(fetcher: fetcher, opener: second_opener)
    end

    assert_equal image_url, brand.reload.og_image_url
  end

  private

  def active_storage_tables_available?
    ActiveRecord::Base.connection.data_source_exists?("active_storage_blobs") &&
      ActiveRecord::Base.connection.data_source_exists?("active_storage_attachments")
  end
end
