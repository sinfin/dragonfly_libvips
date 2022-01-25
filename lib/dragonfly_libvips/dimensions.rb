# frozen_string_literal: true

module DragonflyLibvips
  Dimensions = Struct.new(:orig_w, :orig_h, :geom_w, :geom_h, :x_offset, :y_offset, :area, :modifiers, :gravity, keyword_init: true) do
    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end

    def call
      case
        when ignore_aspect_ratio?
          OpenStruct.new(x_scale: horizontal_scale, y_scale: vertical_scale)
        when do_not_resize?
          OpenStruct.new(width: orig_w, height: orig_h, scale: 1)
        when fill_area?
          OpenStruct.new(width: fill_width, height: fill_height)
        when crop_with_gravity?
          OpenStruct.new(resize_width: fill_width,
                         resize_height: fill_height,
                         width: dimensions.width,
                         height: dimensions.height,
                         x: crop_gravity_x_offset,
                         y: crop_gravity_y_offset)
        when crop_without_gravity?
          OpenStruct.new(width: dimensions.width,
                         height: dimensions.height,
                         x: x_offset,
                         y: y_offset)
        else
          OpenStruct.new(width: width, height: height, scale: scale, resize: resize)
      end
    end

    private

    def width
      if landscape?
        dimensions_specified_by_width? ? dimensions.width : dimensions.height / aspect_ratio
      else
        dimensions_specified_by_height? ? dimensions.height / aspect_ratio : dimensions.width
      end
    end

    def height
      if landscape?
        dimensions_specified_by_width? ? dimensions.width * aspect_ratio : dimensions.height
      else
        dimensions_specified_by_height? ? dimensions.height : dimensions.width * aspect_ratio
      end
    end

    def scale
      width.to_f / orig_w
    end

    def horizontal_scale
      orig_w.to_f / geom_w
    end

    def vertical_scale
      orig_h.to_f / geom_h
    end

    def dimensions
      OpenStruct.new(width: geom_w.to_f, height: geom_h.to_f)
    end

    def aspect_ratio
      orig_h.to_f / orig_w
    end

    def dimensions_specified_by_width?
      dimensions.width.positive?
    end

    def dimensions_specified_by_height?
      dimensions.height.positive?
    end

    def landscape?
      aspect_ratio <= 1.0
    end

    def portrait?
      !landscape?
    end

    def resize
      return :down if modifiers&.include? '>'
      return :up if modifiers&.include? '>'
      return :both
    end

    def do_not_resize_if_image_smaller_than_requested?
      return false unless modifiers&.include? '>'

      orig_w < geom_w && orig_h < geom_h
    end

    def do_not_resize_if_image_larger_than_requested?
      return false unless modifiers&.include? '<'

      orig_w > geom_w && orig_h > geom_h
    end

    def do_not_resize?
      do_not_resize_if_image_smaller_than_requested? || do_not_resize_if_image_larger_than_requested?
    end

    def fill_area?
      modifiers&.include?('^')
    end

    def ignore_aspect_ratio?
      modifiers&.include?('!')
    end

    def crop_with_gravity?
      !!gravity
    end

    def crop_without_gravity?
      !(x_offset.nil? && y_offset.nil?)
    end

    def fill_width
      if orig_w.to_f / orig_h.to_f > dimensions.width / dimensions.height
        # original is wider than the required crop rectangle -> reduce height
        orig_w.to_f * dimensions.height / orig_h.to_f
      else
        # original is narrower than the required crop rectangle -> reduce width
        dimensions.width
      end
    end

    def fill_height
      fill_width * orig_h.to_f / orig_w.to_f
    end

    def crop_gravity_x_offset
      case gravity
        when /c/
          (fill_width - dimensions.width) / 2
        when /e/
          fill_width - dimensions.width
        when /w/
          0
        when /[ns]/
          (fill_width - dimensions.width) / 2
        else
          throw "Unknown gravity"
      end
    end

    def crop_gravity_y_offset
      case gravity
        when /c/
          (fill_height - dimensions.height) / 2
        when /n/
          0
        when /s/
          fill_height - dimensions.height
        when /[ew]/
          (fill_height - dimensions.height) / 2
        else
          throw "Unknown gravity"
      end
    end
  end
end
