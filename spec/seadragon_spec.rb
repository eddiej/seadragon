require 'spec_helper'

describe Seadragon do
  let(:valid_parameters){
    {
      source_path: "#{File.dirname(__FILE__)}/fixtures/images/seadragon.jpg",
      tiles_path: "/tmp/tiles",
      handle: "leafydragon", 
      tile_size: 256,
      overlap: 2,
      quality: 90,
      format: 'png'
    }
  }
  subject{
    Seadragon::Slicer.new(valid_parameters)
  }

  it 'has a version number' do
    expect(Seadragon::VERSION).not_to be nil
  end

  describe 'initializer' do
    context 'invalid params' do
      it 'raises an exception if paths are missing' do
        expect{Seadragon::Slicer.new}
          .to raise_error(ArgumentError, 
            "source and destination paths are required")
      end
      it 'raises an exception if a handle is missing' do
        expect{Seadragon::Slicer.new(source_path: 'a', tiles_path: 'b')}
          .to raise_error(ArgumentError, 
            "a handle is required")
      end
    end
    context 'valid params' do    
      it 'overrides the default values' do
        expect(subject.tile_size).to eq 256
        expect(subject.overlap).to eq 2
        expect(subject.quality).to eq 90
        expect(subject.format).to eq 'png'
      end
    end
  end

  describe 'slice!' do
    before do
      delete_generated_files
      subject.slice!
    end
    after do
      delete_generated_files
    end
    it 'creates tile images' do
      expect(File)
        .to exist("/tmp/tiles/leafydragon_files")
    end
  end

  describe 'write_dzi_specification' do
    before do
      delete_generated_files
      subject.write_dzi_specification
    end
    after do
      delete_generated_files
    end
    it 'creates a DZI file' do
      expect(File)
        .to exist("/tmp/tiles/leafydragon.dzi")
    end
  end

  describe 'private methods' do
    describe 'max_level' do
      it 'returns times an image can be halved before reaching 1x1' do
        expect(subject.send(:max_level, 1, 1)).to eq 0
        expect(subject.send(:max_level, 2, 2)).to eq 1
        expect(subject.send(:max_level, 30, 30)).to eq 5
        expect(subject.send(:max_level, 100, 100)).to eq 7
        expect(subject.send(:max_level, 3000, 3000)).to eq 12 
      end
    end
    describe 'tile_dimensions' do
      it 'returns width and height for a tile, dependant on its position' do
        expect(subject.send(:tile_dimensions, 0, 0, 256, 1)).to eq [257, 257]
        expect(subject.send(:tile_dimensions, 12, 12, 256, 1)).to eq [258, 258]
      end
    end
  end

  private 

  def delete_generated_files
    FileUtils.rm_rf(subject.tiles_path) if File.exists?(subject.tiles_path)
  end
  
end

RSpec.describe Seadragon::SeadragonHelper, type: :helper do
  it "raises an exception if the id param is missing" do
    expect{helper.seadragon()}
      .to raise_error(ArgumentError, 
        "a target element must be passed via the id key")
  end
  it "raises an exception if the tileSources param is missing" do
    expect{helper.seadragon(id: 'someid')}
      .to raise_error(ArgumentError, 
        "a tile source must be passed via the tileSources key")
  end
end
