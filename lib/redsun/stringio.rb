#!/usr/bin/ruby


class String
  def pack_as_hex
    result = ""
    (0...length/2).each { |i| result = result << self[i*2..i*2+1].to_i(16).chr }
    #(0...length).each_slice(2) { |i| result <<= self[i[0]..i[-1]].to_i(16).chr }
    result
  end
  def unpack_as_hex
    result = ""
    each_byte { |b| result = result << sprintf("%0.2x",b)}
    result
  end
  def pack_as_binary
    result = ""
    (0...length/8).each { |i| result = result << self[i*8..i*8+7].to_i(2).chr }
    result
  end
end

module Math
  def Math.log2 n
    Math.log(n)/Math.log(2)
  end
end

class Integer
  def sbits
    return 2 if self == 0
    Math.log2(self.abs).floor + 2
  end
  def ubits
    return 1 if self == 0
    Math.log2(self.abs).floor + 1
  end
end

module RedSun

  class StringSwfIO
    attr_accessor :pos, :bit_pos, :cur_byte, :source, :mode

    def initialize source=nil # needs rspec
      if source
        @source = source
      else
        @source = ""
      end
      @pos = 0
      @bit_pos = 0
      @mode = nil
    end

    def flush
      clear_bit_pos
    end

    def rewind
      flush
      @pos = 0
      @mode = nil
    end

    def read_mode_guard
      if @mode == :write
        raise StandardError, "can't read in write mode without rewinding first"
      elsif @mode == :read
        true
      else
        @mode = :read
        true
      end
    end
    private :read_mode_guard

    def write_mode_guard
      if @mode == :read
        raise StandardError, "can't write in read mode without rewinding first"
      elsif @mode == :write
        true
      else
        @mode = :write
        @source = ""
        true
      end
    end
    private :write_mode_guard

    def read(length=nil, buffer=nil) # needs rspec
      read_mode_guard
      if buffer
        if length == nil
          buffer.replace @source[@pos..-1]
          @pos = @source.length
        else
          buffer.replace @source[@pos...@pos+length]
          @pos += length
        end
        buffer
      else
        if length == nil
          ret = @source[@pos..-1]
          @pos = @source.length
        else
          ret = @source[@pos...@pos+length]
          @pos += length
        end
        ret
      end
    end
    def clear_bit_pos # needs rspec
      # If we're writing, then write the partial byte now
      if @mode == :write and @bit_pos != 0
        putc @cur_byte
      end
      @bit_pos = 0
      @cur_byte = nil
    end
    private :clear_bit_pos
    def write str # needs rspec
      write_mode_guard
      clear_bit_pos
      @source <<= str
      @pos = @source.length
    end
    def getc # needs rspec
      read_mode_guard
      ch = @source[@pos]
      return nil if not ch
      ret = ch.bytes.to_a[0]
      #Kernel.puts("getc 0x#{ret.to_s(16)}")
      @pos += 1
      ret
    end
    def putc char # needs rspec
      write_mode_guard
      @source <<= char.chr
      @pos += 1
    end
    def write_fixed8 v
      write_mode_guard
      clear_bit_pos
      ui16 = (v[:whole] << 8) | (v[:fraction]&0xFF)
      write_ui16 ui16
    end
    def read_fixed8
      read_mode_guard
      clear_bit_pos
      ui16 = read_ui16
      {:whole=>(ui16>>8), :fraction=>(ui16&0xFF)}
    end
    def read_ui16
      read_mode_guard
      clear_bit_pos
      byte = getc
      return nil if !byte
      v = byte
      byte = getc
      return nil if !byte
      v |= byte << 8;
    end
    def read_ui32
      read_mode_guard
      clear_bit_pos
      byte = getc
      return nil if byte==nil
      v = byte
      byte = getc
      return nil if !byte
      v |= byte << 8;
      byte = getc
      return nil if !byte
      v |= byte << 16;
      byte = getc
      return nil if !byte
      v |= byte << 24;
    end
    def read_ui8
      read_mode_guard
      clear_bit_pos # needs rspec
      getc
    end
    def read_s24
      read_mode_guard
      clear_bit_pos
      byte = getc
      return nil if !byte
      v = byte
      byte = getc
      return nil if !byte
      v |= byte << 8;
      byte = getc
      return nil if !byte
      v |= byte << 16;
      v = (v-0x1000000) if v & 0x800000 != 0
      v
    end
    def write_s24 v
      write_mode_guard
      clear_bit_pos # needs rspec
      putc v & 0xFF;
      putc (v >> 8) & 0xFF;
      putc (v >> 16) & 0xFF;
    end
    def write_ui8 v
      write_mode_guard
      clear_bit_pos # needs rspec
      putc v & 0xFF
    end
    def write_si8 v
      write_mode_guard
      clear_bit_pos # needs rspec
      putc v & 0xFF
    end
    def write_ui16 v
      write_mode_guard
      clear_bit_pos # needs rspec
      putc v & 0xFF;
      putc (v >> 8) & 0xFF;
    end
    def write_ui32 v
      write_mode_guard
      clear_bit_pos # needs rspec
      putc v & 0xFF;
      putc (v >> 8) & 0xFF;
      putc (v >> 16) & 0xFF;
      putc (v >> 24) & 0xFF;
    end
    def write_u30 v
      write_u32 (v & 0x3fffffff)
    end
    def write_u32 v
      write_mode_guard
      clear_bit_pos # needs rspec
      bits = v.ubits
      shift = 0
      while bits > 0
        this_val = (v >> shift) & 0x7F
        if (bits > 7)
          this_val |= 0x80
        end
        putc this_val

        shift += 7
        bits -= 7
      end
    end
    def read_u30
      read_u32 & 0x3fffffff
    end
    def read_u32
      read_mode_guard
      clear_bit_pos # needs rspec

      byte = getc
      shift = 0
      value = 0
      while byte != nil
        if byte & 0x80 == 0
          return value | (byte << shift)
        else
          value = value | ((byte &0x7F) << shift)
        end
        shift += 7
        byte = getc
      end

    end
    def read_s32
      read_mode_guard
      clear_bit_pos # needs rspec

      byte = getc
      shift = 0
      value = 0
      while byte != nil
        if byte & 0x80 == 0
          byte = (byte-128) if byte & 0x40 != 0
          return value | (byte << shift)
        else
          value = value | ((byte &0x7F) << shift)
        end
        shift += 7
        byte = getc
      end

    end
    def write_s32 v
      write_mode_guard
      clear_bit_pos # needs rspec
      bits = v.ubits
      shift = 0
      while bits > 0
        this_val = (v >> shift) & 0x7F
        if (bits > 7)
          this_val |= 0x80
        end
        putc this_val

        shift += 7
        bits -= 7
      end
    end
    def write_d64(v)
      lower = v & 0xFFFFFFFF;
      upper = v >> 32;
      write_ui32 upper
      write_ui32 lower
    end
    def read_d64
      upper = read_ui32
      lower = read_ui32
      (upper << 32) | lower
    end
    def read_argb
      read_rgba
    end
    def read_rgba
      byte = getc
      return nil if not byte
      rgb = byte << 24
      byte = getc
      return nil if not byte
      rgb |= byte << 16
      byte = getc
      return nil if not byte
      rgb |= byte << 8
      byte = getc
      return nil if not byte
      rgb |= byte
    end
    def write_argb p1, p2=nil, p3=nil, p4=nil
      write_rgba p1, p2, p3, p4
    end
    def write_rgba p1, p2=nil, p3=nil, p4=nil
      if not p2 or not p3 or not p4
        rgba = p1
        p1 = (rgba >> 24) & 0xFF
        p2 = (rgba >> 16) & 0xFF
        p3 = (rgba >> 8) & 0xFF
        p4 = rgba & 0xFF
      end
      write_ui8 p1
      write_ui8 p2
      write_ui8 p3
      write_ui8 p4
    end
    def read_rgb
      byte = getc
      return nil if not byte
      rgb = byte << 16
      byte = getc
      return nil if not byte
      rgb |= byte << 8
      byte = getc
      return nil if not byte
      rgb |= byte
    end
    def write_rgb p1, p2=nil, p3=nil
      if not p2 or not p3
        rgb = p1
        p1 = (rgb >> 16) & 0xFF
        p2 = (rgb >> 8) & 0xFF
        p3 = rgb & 0xFF
      end
      write_ui8 p1
      write_ui8 p2
      write_ui8 p3
    end
    def write_rect rect
      write_mode_guard
      clear_bit_pos # needs rspec
      largest = 0
      actual_value = 0
      rect.each_value {|v|
        if v.abs > largest
          largest = v.abs
          actual_value = v
        end
      }
      bits = largest.sbits
      #Kernel.puts "largest value has #{bits} bits."
      write_ubits 5, bits
      write_sbits bits, rect[:xmin]
      write_sbits bits, rect[:xmax]
      write_sbits bits, rect[:ymin]
      write_sbits bits, rect[:ymax]
    end
    def write_sbits bits_towrite, value
      write_bits bits_towrite, value
    end
    def write_ubits bits_towrite, value
      write_bits bits_towrite, value
    end
    def write_bits bits_towrite, value
      # clamp value
      value = value & ((1<<bits_towrite)-1)
      write_mode_guard
      bits_left = bits_towrite
      while bits_left > 0
        bits = 8 - @bit_pos
        if @bit_pos == 0
          @cur_byte = 0
        else
        end
        if bits_left >= bits
          rem_bits = 0
          bits_left -= bits
          @bit_pos = 0
        else
          rem_bits = bits - bits_left
          bits_left = 0
          @bit_pos = 8 - rem_bits
        end
        @cur_byte |= ((value >> bits_left) << rem_bits) & 0xFF
        #Kernel.puts "curbyte is #{@cur_byte}."
        if (rem_bits == 0)
          putc @cur_byte
        end
      end
      #Kernel.puts "all done writing bits"
    end
    def read_rect
      read_mode_guard
      bits = read_bits 5;
      #Kernel.puts("bits: #{bits} total: #{(5+bits*4)}");
      xmin = read_bits bits
      xmax= read_bits bits
      ymin = read_bits bits
      ymax = read_bits bits
      {:xmin=>xmin, :xmax=>xmax, :ymin=>ymin, :ymax=>ymax}
    end
    def read_bits bits_toread
      read_mode_guard
      bits_left = bits_toread
      result = 0
      while bits_left > 0
        #Kernel.puts "Reading with #{bits_left} bits left at #{@bit_pos}."
        bits = 8 - @bit_pos
        # If bit_pos is zero then we need to read another byte and no mask
        if @bit_pos == 0
          @cur_byte = getc
          mask = nil
        else
          mask = (1<<bits) - 1
        end
        # if we're reading all the bits, then zero it out
        if bits_left >= bits
          rem_bits = 0
          @bit_pos = 0
          bits_left -= bits
        else
          rem_bits = bits - bits_left
          @bit_pos = 8 - rem_bits
          bits_left = 0
        end
        if mask
          result |= ((@cur_byte & mask) >> rem_bits) << bits_left
        else
          result |= (@cur_byte >> rem_bits) << bits_left
        end
      end
      #Kernel.puts "Done with bit pos #{@bit_pos} and last byte #{@cur_byte.to_s(16)}."
      return result
    end

    def write_string str
      write_mode_guard
      clear_bit_pos # needs rspec
      write str
      putc 0x00
    end
    def read_string
      read_mode_guard
      clear_bit_pos # needs rspec
      res = ""
      while true
        byte = getc
        break if byte == 0x00
        res <<= byte
      end
      res
    end
    def read_string_info
      read_mode_guard
      clear_bit_pos # needs rspec
      size = read_u30
      if size > 0
        res = read size
      else
        ""
      end
    end
    def write_string_info str
      write_mode_guard
      clear_bit_pos # needs rspec
      write_u30 str.length
      if str.length > 0
        write str
      end
    end
  end

end
