require 'vips'
require 'dragonfly_libvips/processors'

module DragonflyLibvips
  module Processors
    class ExtractArea
      include DragonflyLibvips::Processors

      def call(content, x, y, width, height, options = {})
        wrap_process(content, **options) do |img, **_input_options|
          img.extract_area(x, y, width, height)
        end
      end
    end
  end
end
