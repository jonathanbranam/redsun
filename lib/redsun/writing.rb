#!/usr/bin/ruby

require 'zlib'
require 'redsun/stringio'
require 'redsun/tags'

module RedSun

  class Swf

    def write
      contents = write_to_string
      new_file = ABCFile.new(@filename+".swf","w")
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

    def write_contents(contents)
      @tags.each do |tag|
        contents.write tag.to_s
      end
    end

  end

  module ABC

    class ABCFile

      def to_s
        io = StringSwfIO.new
        write_to_io(io)
        io.rewind
        io.read

      end

      def write_to_io(io)
        io.write_ui16 @minor_version
        io.write_ui16 @major_version

        @constant_pool.write_to_io(io)

        io.write_u30 @abc_methods.length
        @abc_methods.each { |v| v.write_to_io(io) }

        io.write_u30 @metadatas.length
        @metadatas.each { |v| v.write_to_io(io) }

        io.write_u30 @classes.length
        @instances.each { |v| v.write_to_io(io) }
        @classes.each { |v| v.write_to_io(io) }

        io.write_u30 @scripts.length
        @scripts.each { |v| v.write_to_io(io) }

        io.write_u30 @method_bodies.length
        @method_bodies.each { |v| v.write_to_io(io) }

      end

    end

    class ConstantPool


      def write_to_io(io)
        write_skip_first(io, @ints      ){ |v| io.write_s32(v) }
        write_skip_first(io, @uints     ){ |v| io.write_u32(v) }
        write_skip_first(io, @doubles   ){ |v| io.write_d64(v) }
        write_skip_first(io, @strings   ){ |v| io.write_string_info(v.to_s) }
        write_skip_first(io, @namespaces){ |v| v.write_to_io(io) }
        write_skip_first(io, @ns_sets   ){ |v| v.write_to_io(io) }
        write_skip_first(io, @multinames){ |v| v.write_to_io(io) }

        self
      end

      def write_skip_first io, arr
        if arr.length > 1
          io.write_u30 arr.length
          1.upto(arr.length-1) do |i|
            yield arr[i]
          end
        else
          io.write_u30 0
        end
      end


    end

  end

end
