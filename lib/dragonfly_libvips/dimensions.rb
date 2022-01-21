module DragonflyLibvips
  class Dimensions < Struct.new(:geometry, :orig_w, :orig_h, :crop_x_ratio, :crop_y_ratio)
    def self.call(*args)
      new(*args).call
    end

    def call
      if crop_image?
        return OpenStruct.new(width: precrop_width,
                              height: precrop_height,
                              crop_width: dimensions.width,
                              crop_height: dimensions.height,
                              crop_x: crop_x_ratio ? dimensions.width * crop_x_ratio.to_f : nil,
                              crop_y: crop_y_ratio ? dimensions.height * crop_y_ratio.to_f : nil,
                              crop: true)
      end

      if do_not_resize_if_image_smaller_than_requested? || do_not_resize_if_image_larger_than_requested?
        return OpenStruct.new(width: orig_w,
                              height: orig_h,
                              scale: 1)
      end

      OpenStruct.new(width: width, height: height, scale: scale)
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
      width.to_f / orig_w.to_f
    end

    def dimensions
      w, h = geometry.scan(/\A(\d*)x(\d*)/).flatten.map(&:to_f)
      OpenStruct.new(width: w, height: h)
    end

    def aspect_ratio
      orig_h.to_f / orig_w
    end

    def dimensions_specified_by_width?
      dimensions.width > 0
    end

    def dimensions_specified_by_height?
      dimensions.height > 0
    end

    def landscape?
      aspect_ratio <= 1.0
    end

    def portrait?
      !landscape?
    end

    def do_not_resize_if_image_smaller_than_requested?
      return false unless geometry.end_with? '>'
      orig_w < width && orig_h < height
    end

    def do_not_resize_if_image_larger_than_requested?
      return false unless geometry.end_with? '<'
      orig_w > width && orig_h > height
    end

    def crop_image?
      geometry.end_with? '#'
    end

    def precrop_width
      if orig_w.to_f / orig_h.to_f > dimensions.width / dimensions.height
        # original is wider than the required crop rectangle -> reduce height
        orig_w.to_f * dimensions.height / orig_h.to_f
      else
        # original is narrower than the required crop rectangle -> reduce width
        dimensions.width
      end
    end

    def precrop_height
      precrop_width * orig_h.to_f / orig_w.to_f
    end
  end
end
