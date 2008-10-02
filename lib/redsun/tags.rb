#!/usr/bin/ruby

require 'redsun/stringio'
require 'redsun/abc'

module RedSun

  class SwfTag
    attr_accessor :type, :contents
    def initialize type=nil, contents=nil
      @type = type
      @contents = contents
      #parse_contents if @contents
      parse_contents if @contents
    end

    def to_s
      strio = StringSwfIO.new
      update_contents
      length = @contents.length
      if length < 0x3F
        ui16 = @type << 6 | length
        strio.write_ui16 ui16
      else
        ui16 = @type << 6 | 0x3F
        strio.write_ui16 ui16
        strio.write_ui32 length
      end
      strio.write @contents
      strio.rewind
      strio.read
    end

    def parse_contents
    end

    def update_contents
    end
  end

  class EndTag < SwfTag
    TagId = 0
    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      @contents = ""
    end
    def update_contents
      @contents = ""
    end
  end

  class ShowFrameTag < SwfTag
    TagId = 1
    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      @contents = ""
    end
    def update_contents
      @contents = ""
    end
  end

  class SetBackgroundColorTag < SwfTag
    TagId = 9
    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    attr_accessor :background_color

    def parse_contents
      io = StringSwfIO.new @contents
      @background_color = io.read_rgb
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_rgb @background_color
      io.rewind
      @contents = io.read
    end
  end

  class ProductInfoTag < SwfTag
    TagId = 41
    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
  end

  class FrameLabelTag < SwfTag
    TagId = 43
    attr_accessor :name

    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      io = StringSwfIO.new @contents
      @name = io.read_string
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_string @name
      io.rewind
      @contents = io.read
    end
  end

  class DebugIdTag < SwfTag
    TagId = 63
    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
  end

  class EnableDebugger2Tag < SwfTag
    TagId = 64
    attr_accessor :password, :reserved1

    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      io = StringSwfIO.new @contents
      # This is supposed to be all zeros, but it isn't in my test
      @reserved1 = io.read_ui16
      @password = io.read_string
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_ui16 @reserved1
      io.write_string @password
      io.rewind
      @contents = io.read
    end
  end

  class ScriptLimitsTag < SwfTag
    TagId = 65
    attr_accessor :max_recursion_depth, :script_timeout_secs

    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      io = StringSwfIO.new @contents
      @max_recursion_depth = io.read_ui16
      @script_timeout_secs = io.read_ui16
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_ui16 @max_recursion_depth
      io.write_ui16 @script_timeout_secs
      io.rewind
      @contents = io.read
    end
  end

  class SymbolClassTag < SwfTag
    TagId = 76
    attr_accessor :symbols

    def initialize type=nil, contents=nil
      @symbols = []
      super(TagId, contents)
    end

    def parse_contents
      io = StringSwfIO.new @contents
      num_symbols = io.read_ui16
      #Kernel.puts "has symbols #{num_symbols}."
      1.upto(num_symbols) do |i|
        #Kernel.puts "Reading symbol #{i}."
        tag = io.read_ui16
        name = io.read_string
        @symbols <<= {:tag=>tag, :name=>name}
      end
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_ui16 @symbols.length
      @symbols.each do |symbol|
        io.write_ui16 symbol[:tag]
        io.write_string symbol[:name]
      end
      io.rewind
      @contents = io.read
    end
  end

  class MetadataTag < SwfTag
    TagId = 77
    attr_accessor :metadata

    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      io = StringSwfIO.new @contents
      @metadata = io.read_string
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_string @metadata
      io.rewind
      @contents = io.read
    end
  end

  class DoABCTag < SwfTag
    TagId = 82
    attr_accessor :flags, :name, :abc_file

    def initialize type=nil, contents=nil
      super(TagId, contents)
    end
    def parse_contents
      io = StringSwfIO.new @contents
      @flags = io.read_ui32
      @name = io.read_string
      abc_data = io.read
      @abc_file = ABC::ABCFile.new
      @abc_file.read_from_str(abc_data)
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_ui32(@flags)
      io.write_string(@name)
      #io.write @abc_data
      @abc_file.write_to_io(io)
      io.rewind
      @contents = io.read
    end
  end

  class FileAttributesTag < SwfTag
    TagId = 69
    attr_accessor :has_metadata, :actionscript3, :use_network
    attr_accessor :reserved1, :reserved2, :reserved3

    def initialize type=nil, contents=nil
      super(TagId, contents)
      @reserved1 = 0
      @reserved2 = 0
      @reserved3 = 0
    end

    def parse_contents
      io = StringSwfIO.new @contents
      @reserved1 = io.read_bits 3
      @has_metadata = io.read_bits(1) == 1
      @actionscript3 = io.read_bits(1) == 1
      @reserved2 = io.read_bits 2
      @use_network = io.read_bits(1) == 1
      @reserved3 = io.read_bits 24
      @contents = nil
    end

    def update_contents
      io = StringSwfIO.new
      io.write_bits 3, 0
      io.write_bits 1, @has_metadata ? 1 : 0
      io.write_bits 1, @actionscript3 ? 1 : 0
      io.write_bits 2, 0
      io.write_bits 1, @use_network ? 1 : 0
      io.write_bits 24, 0
      io.rewind
      @contents = io.read
    end
  end

end
