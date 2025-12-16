# frozen_string_literal: true

require 'vips'
require 'dragonfly_libvips/processors'

module DragonflyLibvips
  module Processors
    class Noop
      include DragonflyLibvips::Processors

      def call(content, options = {})
        wrap_process(content, **options) do |img, **_input_options|
          img
        end
      end
    end
  end
end
