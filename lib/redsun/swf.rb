#!/usr/bin/ruby

require 'zlib'
require 'redsun/stringio'
require 'redsun/tags'

module RedSun

  class Swf
    attr_accessor :filename, :file

    attr_accessor :body_io

    attr_accessor :sig, :version, :length, :compressed

    attr_accessor :frame_size, :frame_rate, :frame_count
    attr_accessor :tags

    def initialize(filename=nil)
      @tag_class = Hash.new( SwfTag )
      @tag_class[0]= EndTag
      @tag_class[1]= ShowFrameTag
      @tag_class[9]= SetBackgroundColorTag
      @tag_class[41]= ProductInfoTag
      @tag_class[43]= FrameLabelTag
      @tag_class[63]= DebugIdTag
      @tag_class[64]= EnableDebugger2Tag
      @tag_class[65]= ScriptLimitsTag
      @tag_class[69]= FileAttributesTag
      @tag_class[76]= SymbolClassTag
      @tag_class[77]= MetadataTag
      @tag_class[82]= DoABCTag
      @tags = []

      set_defaults

      @filename = filename
      open @filename if @filename
    end
    def set_defaults
      @compressed = false
      @version = 9
      @frame_size = {:xmin=>0,:xmax=>10000,:ymin=>0,:ymax=>7500}
      @frame_rate = {:whole=>24,:fraction=>0}
      @frame_count = 1
    end

    def tag_select(clazz)
      @tags.select { |t| t.class == clazz }
    end

    def abc_files
      @tags.select { |t| t.class == DoABCTag }.map { |t| t.abc_file }
    end

    def scripts
      abc_files.map { |f| f.scripts }.flatten
    end

    def abc_methods
      abc_files.map { |f| f.abc_methods }.flatten
    end

    def instances
      abc_files.map { |f| f.instances }.flatten
    end

    def instance(name, ns=nil)
      res = instances.select do |i|
        i.name.name == name and (not ns or i.name.ns.name == ns)
      end.flatten

      if res.length == 0
        nil
      elsif res.length == 1
        res.first
      else
        res
      end
    end

    def abc_method(name)
      res = abc_methods.select { |m| m.name == name }.flatten

      if res.length == 0
        nil
      elsif res.length == 1
        res.first
      else
        res
      end
    end
  end

end
