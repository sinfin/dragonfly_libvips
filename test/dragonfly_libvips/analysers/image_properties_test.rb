require 'test_helper'

describe DragonflyLibvips::Analysers::ImageProperties do
  let(:app) { test_libvips_app }
  let(:analyser) { DragonflyLibvips::Analysers::ImageProperties.new }
  let(:png) { Dragonfly::Content.new(app, SAMPLES_DIR.join('sample.png')) } # 280x355
  let(:jpg) { Dragonfly::Content.new(app, SAMPLES_DIR.join('sample.jpg')) } # 280x355

  it { analyser.call(png).must_equal('format' => 'png', 'width' => 280, 'height' => 355, 'xres' => 72.0, 'yres' => 72.0, 'progressive' => false) }

  describe 'jpgs' do
    it { analyser.call(jpg)['progressive'].must_equal false }
  end

  describe 'misnamed files (wrong extension)' do
    # WebP file with .jpg extension - tests the autorotate fallback
    let(:webp_as_jpg) { Dragonfly::Content.new(app, SAMPLES_DIR.join('sample_webp_misnamed.jpg')) }

    it 'extracts dimensions even when file extension does not match content' do
      result = analyser.call(webp_as_jpg)
      result['width'].must_equal 280
      result['height'].must_equal 355
      result['format'].must_equal 'jpg'
    end
  end
end
