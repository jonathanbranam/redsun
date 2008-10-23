#!/usr/bin/ruby

require 'zlib'
require 'redsun/stringio'
require 'redsun/tags'

module RedSun

  class Swf

    def open(filename)
      @filename = filename
      @file = File.new(@filename, "r")
      @file.binmode
      @swf_io = StringSwfIO.new(@file.read)
      @file.close
      read_swf
    end

    def read_from(string)
      @swf_io = StringSwfIO.new(string)
      read_swf
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
      new_tag = parse_tag(tag_type, tag_contents)
      @tags << new_tag
      new_tag
    end

    def parse_tag(tag_type, tag_contents)
      @tag_class[tag_type].new(tag_type, tag_contents)
    end

    def uncompress_swf(filename)
      @filename = filename
      @file = ABCFile.new(@filename, "r")
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
      # unpack -> pack to work around encoding errors
      "F" +
        file_contents[1..7].unpack_as_hex.pack_as_hex + 
        @body_io.read.unpack_as_hex.pack_as_hex

    end

  end

  module ABC



    class ABCFile

      attr_accessor :contents
      def read_from_str str
        @contents = str
        read_from_io(StringSwfIO.new(str))
      end

      def read_from_io(io)
        clear_arrays

        @minor_version = io.read_ui16
        @major_version = io.read_ui16

        @constant_pool.read_from_io(io)

        method_count = io.read_u30
        1.upto(method_count) do
          @abc_methods << Method.new_from_io(io, self)
        end

        metadata_count = io.read_u30
        1.upto(metadata_count) do
          @metadatas << Metadata.new(io, self)
        end

        class_count = io.read_u30
        1.upto(class_count) do |i|
          @instances << Instance.new_from_io(io, self)
        end
        1.upto(class_count) do |i|
          c = Class.new_from_io(io, self)
          @classes << c
          @instances[i-1].abc_class = c
        end

        script_count = io.read_u30
        1.upto(script_count) do
          @scripts << Script.new_from_io(io, self)
        end

        method_body_count = io.read_u30
        1.upto(method_body_count) do
          @method_bodies << MethodBody.new_from_io(io, self)
        end

      end

    end

    class ConstantPool

      def read_from_io(io)
        clear_arrays

        int_count = io.read_u30
        #puts("Reading #{int_count} constant ints.")
        2.upto(int_count) do
          @ints << io.read_s32
        end

        uint_count = io.read_u30
        #puts("Reading #{uint_count} constant uint.")
        2.upto(uint_count) do
          @uints << io.read_u32
        end

        double_count = io.read_u30
        #puts("Reading #{double_count} constant double.")
        2.upto(double_count) do
          @doubles << io.read_d64
        end

        string_count = io.read_u30
        #puts("Reading #{string_count} constant string.")
        2.upto(string_count) do
          string_value = io.read_string_info
          @strings << string_value.to_sym
        end

        namespace_count = io.read_u30
        #puts("Reading #{namespace_count} constant namespace.")
        2.upto(namespace_count) do
          ns = Namespace.new_from_io(io, self)
          @namespaces << ns
        end

        ns_set_count = io.read_u30
        #puts("Reading #{ns_set_count} constant ns_set.")
        2.upto(ns_set_count) do
          ns = NsSet.new_from_io(io, self)
          @ns_sets << ns
        end

        multiname_count = io.read_u30
        #puts("Reading #{multiname_count} constant multiname.")
        2.upto(multiname_count) do
          ns = Multiname.new_from_io(io, self)
          @multinames << ns
        end

        self
      end


    end

  end

end
