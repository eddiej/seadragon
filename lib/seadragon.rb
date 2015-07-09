require 'rmagick'
require 'json'
require "seadragon/version"
require "seadragon/engine"

module Seadragon

class Slicer
  attr_accessor :source_path, :tiles_path, :handle, :tile_size, :overlap, 
    :quality, :format, :dzi_name, :source_image, :width, :height

  def initialize(attributes = {})
    raise ArgumentError.new('source and destination paths are required') unless attributes[:source_path] && attributes[:tiles_path]
    raise ArgumentError.new('a handle is required') unless attributes[:handle]
  
    @source_path  = attributes[:source_path]
    @tiles_path   = attributes[:tiles_path]
    @handle       = attributes[:handle]
    @tile_size    = attributes[:tile_size] || 512 
    @overlap      = attributes[:overlap] || 1
    @quality      = attributes[:quality] || 100
    @format       = attributes[:format] || 'jpg' 

    raise ArgumentError.new("source file doesn't exist") unless File.exist? @source_path
    @source_image = Magick::Image.read(@source_path)[0] # an Image object.
    @width, @height = @source_image.columns, @source_image.rows # image dims

  end

  ##
  # Generates the tiles.
  ##
  def slice!
    # duplicate the source image, we'll be resizing it for each zoom layer.
    image = @source_image.dup 

    # create a parent folder for all of the tiles
    FileUtils.mkdir_p( File.join(tiles_path, handle+"_files") )

    max_level(width, height).downto(0) do |level|

      # get dimensions of the image (image is resized on each iteration)
      current_level_width, current_level_height = image.columns, image.rows 
      current_level_dir = File.join(tiles_path, handle+"_files", level.to_s)
      FileUtils.mkdir_p(current_level_dir) # create dir for current level
      
      # iterate over columns
      x, col_count = 0, 0
      while x < current_level_width
        # iterate over rows
        y, row_count = 0, 0
        while y < current_level_height
          tile_file_path = File.join(current_level_dir, 
            "#{col_count}_#{row_count}.#{format}")
          tile_width, tile_height = tile_dimensions(x, y, tile_size, overlap)
          save_tile(image, tile_file_path, x, y, tile_width, tile_height, quality) unless File.exist? tile_file_path
          y += (tile_height - (2 * overlap))
          row_count += 1
        end
        x += (tile_width - (2 * overlap))
        col_count += 1
      end
      image.resize!(0.5)
    end
    image.destroy!
  end

  ##
  # Generates the DZI (Deep Zoom Image format) descriptor file in JSON.
  ##
  def write_dzi_specification
    properties = {
      'Image': {
        'xmlns':  "http://schemas.microsoft.com/deepzoom/2008",
        'Format':  format,
        'Overlap':  overlap.to_s,
        'TileSize':  tile_size.to_s,
        'Size': {
          'Height': height.to_s,
          'Width': width.to_s
        }
      }
    }
    
    FileUtils.mkdir(tiles_path) unless File.exists?(tiles_path)
    dzi_path = File.join(tiles_path, handle + ".dzi")
    
    File.open(dzi_path, 'w') do |f|
      f.write(JSON.pretty_generate(properties))
    end
  end

  private

  ##
  # Calculates how many times an image can
  # be halved until it is resized to 1x1px.
  ##
  def max_level(width, height)
    return (Math.log([width, height].max) / Math.log(2)).ceil
  end

  ##
  # Determines width and height for tiles, dependent of tile position.
  # Center tiles: overlapping on each side.
  # Borders: no overlapping on the border side, overlapping on other sides.
  # Corners: only overlapping on the right and lower border.
  ##
  def tile_dimensions(x, y, tile_size, overlap)
    overlapping_tile_size = tile_size + (2 * overlap)
    border_tile_size = tile_size + overlap
    tile_width = (x > 0) ? overlapping_tile_size : border_tile_size
    tile_height = (y > 0) ? overlapping_tile_size : border_tile_size
    return tile_width, tile_height
  end

  # Crop a tile from the source image and writes it to dest_path.
  # Params: image: may be an Magick::Image object or a path to an image.
  # dest_path: path where cropped image should be stored.
  # x, y: offset from upper left corner of source image.
  # width, height: width and height of cropped image.
  # quality: compression level 0-100 (or 0.0-1.0), lower number means higher compression.
  def save_tile(image, dest_path, x, y, width, height, quality)
    image = if image.is_a? Magick::Image
            image
          else
            Magick::Image::read(image).first
          end

    quality = quality * 100 if quality < 1

    tile = image.crop(x, y, width, height, true)
    tile.write(dest_path)
  end

end

module SeadragonHelper
  def seadragon(options = {})
    raise ArgumentError.new('a target element must be passed via the id key') unless options[:id]
    raise ArgumentError.new('a tile source must be passed via the tileSources key') unless options[:tileSources]

    options[:prefixUrl] ||= "/assets/openseadragon.github.io/"

    script = javascript_tag("var viewer = OpenSeadragon(#{options.to_json});")
  end
end

ActionView::Base.send :include, SeadragonHelper

end
