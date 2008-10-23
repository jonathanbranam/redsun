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
      @tag_class = Hash.new( Tags::Base )
      @tag_class[0]= Tags::End
      @tag_class[1]= Tags::ShowFrame
      @tag_class[9]= Tags::SetBackgroundColor
      @tag_class[41]= Tags::ProductInfo
      @tag_class[43]= Tags::FrameLabel
      @tag_class[63]= Tags::DebugId
      @tag_class[64]= Tags::EnableDebugger2
      @tag_class[65]= Tags::ScriptLimits
      @tag_class[69]= Tags::FileAttributes
      @tag_class[76]= Tags::SymbolClass
      @tag_class[77]= Tags::Metadata
      @tag_class[82]= Tags::DoABC
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
      @tags.select { |t| t.class == Tags::DoABC }.map { |t| t.abc_file }
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
      name = name.to_sym if not name.is_a? Symbol
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
      name = name.to_sym if not name.is_a? Symbol
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
