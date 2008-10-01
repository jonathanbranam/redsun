#!/usr/bin/ruby

require 'zlib'
require 'redsun/stringio'
require 'redsun/tags'

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
  def create_stub_swf(doc_class_name="EmptySwf", ruby_code=nil)
    set_defaults
    @compressed = true
    @tags = []

    file_attributes = FileAttributesTag.new
    file_attributes.actionscript3 = true
    file_attributes.use_network = true
    file_attributes.has_metadata = false
    @tags << file_attributes

    script_limits = ScriptLimitsTag.new
    script_limits.max_recursion_depth = 1000
    script_limits.script_timeout_secs = 60
    @tags << script_limits

    bg_color = SetBackgroundColorTag.new
    bg_color.background_color = 0x869ca7
    @tags << bg_color

    frame_label = FrameLabelTag.new
    frame_label.name = doc_class_name
    @tags << frame_label

    abc = DoABCTag.new
    abc.flags = 1
    abc.name = "frame1"
    abc.abc_file = ABCFile.new

    empty_swf_ruby = <<HERE
class EmptySwf < Flash::Display::Sprite
  def initialize
    super()
  end
end
HERE
    ruby_code ||= empty_swf_ruby
    vm = VM::InstructionSequence.compile(ruby_code)
    abc.abc_file.load_ruby(vm.to_a)

    @tags << abc

    symbol_class = SymbolClassTag.new
    symbol_class.symbols=[{:tag=>0, :name=>doc_class_name}]
    @tags << symbol_class

    show_frame = ShowFrameTag.new
    @tags << show_frame

    end_tag = EndTag.new
    @tags << end_tag

  end
  def read_from(string)
    @swf_io = StringSwfIO.new(string)
    read_swf
  end
  def open(filename)
    @filename = filename
    @file = File.new(@filename, "r")
    @file.binmode
    @swf_io = StringSwfIO.new(@file.read)
    @file.close
    read_swf
  end
  def uncompress_swf(filename)
    @filename = filename
    @file = File.new(@filename, "r")
    @file.binmode
    file_contents = @file.read
    @file.close
    uncompress_swf_string file_contents
  end
  def uncompress_swf_string(file_contents)
    @swf_io = StringSwfIO.new(file_contents)

    # read just the header to uncompress the SWF
    read_header

    @body_io.rewind
    "F"+file_contents[1..7] + @body_io.read

  end
  def read_swf
    read_header
    read_body
  end
  def read_header
    @sig = @swf_io.read(3)
    @compressed = @sig[0..0] == "C"
    @version = @swf_io.getc
    @length = @swf_io.read_ui32
    if @compressed
      @body_io = StringSwfIO.new(Zlib::Inflate.inflate(@swf_io.read))
    else
      @body_io = StringSwfIO.new(@swf_io.read)
    end
    @frame_size = @body_io.read_rect
    @frame_rate = @body_io.read_fixed8
    @frame_count = @body_io.read_ui16
  end
  def read_body
    while read_tag(@body_io)
    end
  end
  def read_tag(tag)
    tag_header = tag.read_ui16
    return false unless tag_header
    tag_type = tag_header >> 6
    tag_length = tag_header & 0b111111
    # check for long header
    if tag_length == 0x3F
      tag_length = tag.read_ui32
    end
    tag_contents = tag.read tag_length
    new_tag = parse_tag tag_type, tag_contents
    @tags << new_tag
    new_tag
  end
  def parse_tag(tag_type, tag_contents)
    @tag_class[tag_type].new(tag_type, tag_contents)
  end
  def write
    contents = write_to_string
    new_file = File.new(@filename+".new.swf","w")
    new_file.binmode
    new_file.write(contents)
    new_file.close
  end
  def write_to_string
    contents = StringSwfIO.new
    write_pre_header contents

    write_contents contents

    swf_string = StringSwfIO.new
    write_header contents, swf_string

    contents.rewind

    if @compressed
      swf_string.write Zlib::Deflate.deflate(contents.read, Zlib::BEST_COMPRESSION)
    else
      swf_string.write contents.read
    end
    swf_string.flush

    return swf_string.source
  end
  def write_contents(contents)
    @tags.each do |tag|
      contents.write tag.to_s
    end
  end
  def write_pre_header(pre_header)
    pre_header.write_rect @frame_size
    pre_header.write_fixed8 @frame_rate
    pre_header.write_ui16 @frame_count
  end
  def write_header(contents, header)
    if @compressed
      @sig = "CWS"
    else
      @sig = "FWS"
    end
    header.write @sig
    if not @version
      @version = 9
    end

    @length = contents.source.length + 8

    header.write_ui8 @version
    header.write_ui32 @length
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

