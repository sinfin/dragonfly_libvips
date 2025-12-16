require 'bundler/setup'

# Suppress circular require warnings from dragonfly gem
original_verbose = $VERBOSE
$VERBOSE = nil
require 'dragonfly_libvips'
$VERBOSE = original_verbose

require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
require 'minitest/spec'
require 'minitest/pride'

SAMPLES_DIR = Pathname.new(File.expand_path('../../samples', __FILE__))
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

# suppress copious warnings
# warning: method redefined; discarding old <method>
# warning: previous definition of <method> was here
# warning: instance variable @tempfile not initialized
$VERBOSE = nil

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

def test_app(name = nil)
  Dragonfly::App.instance(name).tap do |app|
    app.datastore = Dragonfly::MemoryDataStore.new
    app.secret = 'test secret'
  end
end

def test_libvips_app
  test_app.configure do
    plugin :libvips
  end
end

# Check if HEIC/HEIF encoding is supported by the system's libvips
def heic_supported?
  return @heic_supported if defined?(@heic_supported)

  @heic_supported = begin
    img = Vips::Image.black(1, 1)
    img.heifsave_buffer(compression: 'hevc')
    true
  rescue Vips::Error
    false
  end
end

# Formats that require special codec support
CODEC_DEPENDENT_FORMATS = %w[heic heif avif].freeze
