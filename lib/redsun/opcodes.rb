#!/usr/bin/ruby

require 'redsun/stringio'

module RedSun

  class ABCOpcode
    attr_accessor :opcode, :debug, :op_offset, :opname
    @@subclasses = []
    @@opcodes = nil

    def initialize(abc_file=nil)
      @opcode = self.class.const_get(:Opcode)
      @op_offset = -1
      @abc_file = abc_file
    end
    def read(io)
    end
    def write(io)
      io.write_ui8 @@opcode
    end

    def ABCOpcode.subclasses
      @@subclasses
    end
    def ABCOpcode.get_code(code)
      init_hash if not @@opcodes
      @@opcodes[code]
    end

    def ABCOpcode.init_hash
      @@opcodes = {}
      @@subclasses.each {|oc|
        #puts "********* Opcode #{oc.opcode} already entered in opcodes.***" if @@opcodes[oc.opcode]
        @@opcodes[oc.const_get(:Opcode)] = oc
      }
    end

    def self.inherited(subclass)
      @@subclasses << subclass
      @@opcodes = nil
    end

    def read(io)
    end
    def write(io)
      io.write_ui8 @opcode
    end
    def pretty_print_opname
      sprintf("%5d  %-25s", @op_offset, @opname)
    end
    def pretty_print(show_debug=false)
      return if @debug and not show_debug
      yield pretty_print_opname
    end
    def opname
      if @opname
        @opname
      else
        raise "no opname for #{opcode}."
        self.class.name
      end
    end
  end

  class ABCAdd < ABCOpcode
    Opcode = 0xa0
    def initialize(abc_file)
      super(abc_file)
      @opname = "add"
    end
  end

  class ABCAddI < ABCOpcode
    Opcode = 0xc5
    def initialize(abc_file)
      super(abc_file)
      @opname = "add_i"
    end
  end

  class ABCAsType < ABCOpcode
    Opcode = 0x86
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "astype"
    end
  end

  class ABCAsTypeLate < ABCOpcode
    Opcode = 0x87
    def initialize(abc_file)
      super(abc_file)
      @opname = "astypelate"
    end
  end

  class ABCBitAnd < ABCOpcode
    Opcode = 0xa8
    def initialize(abc_file)
      super(abc_file)
      @opname = "bit_and"
    end
  end
  class ABCBitNot < ABCOpcode
    Opcode = 0x97
    def initialize(abc_file)
      super(abc_file)
      @opname = "bit_not"
    end
  end

  class ABCBitOr < ABCOpcode
    Opcode = 0xa9
    def initialize(abc_file)
      super(abc_file)
      @opname = "bit_or"
    end
  end

  class ABCBitXor < ABCOpcode
    Opcode = 0xaa
    def initialize(abc_file)
      super(abc_file)
      @opname = "bit_xor"
    end
  end

  class ABCCall < ABCOpcode
    Opcode = 0x41
    def read(io)
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "call"
    end
  end

  class ABCCallMethod < ABCOpcode
    attr_accessor :index, :arg_count
    Opcode = 0x43
    def read(io)
      @index = io.read_u30
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "call_method"
    end
  end

  module ABCCallProp
    attr_accessor :index, :arg_count
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 @opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property} with #{@arg_count} args"
    end
    #def initialize(abc_file)
      #super(abc_file)
      #@opname = "call_prop"
    #end
  end

  class ABCCallProperty < ABCOpcode
    Opcode = 0x46
    include ABCCallProp
    def initialize(abc_file, index=nil, arg_count=nil)
      super(abc_file)
      @opname = "call_property"
      @index = index
      @arg_count = arg_count
    end
  end

  class ABCCallPropLex < ABCOpcode
    Opcode = 0x4c
    include ABCCallProp
    def initialize(abc_file, index=nil, arg_count=nil)
      super(abc_file)
      @opname = "call_prop_lex"
      @index = index
      @arg_count = arg_count
    end
  end

  class ABCCallPropVoid < ABCOpcode
    Opcode = 0x4f
    include ABCCallProp
    def initialize(abc_file, index=nil, arg_count=nil)
      super(abc_file)
      @opname = "call_prop_void"
      @index = index
      @arg_count = arg_count
    end
  end

  class ABCCallStatic < ABCOpcode
    attr_accessor :index, :arg_count
    Opcode = 0x44
    def method
      @abc_file.abc_methods[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "call_static"
    end
  end

  class ABCCallSuper < ABCOpcode
    attr_accessor :index, :method, :arg_count
    Opcode = 0x45
    def read(io)
      @index = io.read_u30
      @method = @abc_file.multinames[@index]
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "call_super"
    end
  end

  class ABCCallSuperVoid < ABCOpcode
    attr_accessor :index, :method, :arg_count
    Opcode = 0x4e
    def read(io)
      @index = io.read_u30
      @method = @abc_file.multinames[@index]
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "call_super_void"
    end
  end

  class ABCCheckFilter < ABCOpcode
    Opcode = 0x78
    def initialize(abc_file)
      super(abc_file)
      @opname = "check_filter"
    end
  end

  class ABCCoerce < ABCOpcode
    Opcode = 0x80
    def initialize(abc_file)
      super(abc_file)
      @opname = "coerce"
    end
    def read(io)
      @index = io.read_u30
      @type_name = @abc_file.multinames[@index]
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@type_name}"
    end
  end

  class ABCCoerceA < ABCOpcode
    Opcode = 0x82
    def initialize(abc_file)
      super(abc_file)
      @opname = "coerce_a"
    end
  end

  class ABCCoerceS < ABCOpcode
    Opcode = 0x85
    def initialize(abc_file)
      super(abc_file)
      @opname = "coerce_s"
    end
  end

  class ABCConstruct < ABCOpcode
    attr_accessor :arg_count
    Opcode = 0x42
    def read(io)
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "construct"
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@arg_count}"
    end
  end

  class ABCConstructProp < ABCOpcode
    attr_accessor :index, :arg_count
    Opcode = 0x4a
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
      io.write_u30 @arg_count
    end
    def initialize(abc_file, index=nil, arg_count=nil)
      super(abc_file)
      @opname = "construct_prop"
      @index = index
      @arg_count = arg_count
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property} with #{@arg_count} args"
    end
  end

  class ABCConstructSuper < ABCOpcode
    attr_accessor :arg_count
    Opcode = 0x49
    def read(io)
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @arg_count
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "construct_super"
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@arg_count}"
    end
  end

  class ABCConvertB < ABCOpcode
    Opcode = 0x76
    def initialize(abc_file)
      super(abc_file)
      @opname = "convert_b"
    end
  end

  class ABCConvertI < ABCOpcode
    Opcode = 0x73
    def initialize(abc_file)
      super(abc_file)
      @opname = "convert_i"
    end
  end

  class ABCConvertD < ABCOpcode
    Opcode = 0x75
    def initialize(abc_file)
      super(abc_file)
      @opname = "convert_d"
    end
  end

  class ABCConvertO < ABCOpcode
    Opcode = 0x77
    def initialize(abc_file)
      super(abc_file)
      @opname = "covert_o"
    end
  end

  class ABCConvertU < ABCOpcode
    Opcode = 0x74
    def initialize(abc_file)
      super(abc_file)
      @opname = "convert_u"
    end
  end

  class ABCConvertS < ABCOpcode
    Opcode = 0x70
    def initialize(abc_file)
      super(abc_file)
      @opname = "convert_s"
    end
  end

  class ABCDebug < ABCOpcode
    attr_accessor :debug_type, :index, :name, :reg, :extra
    Opcode = 0xef
    def read(io)
      @debug_type = io.read_ui8
      @index = io.read_u30
      @name = @abc_file.strings[@index]
      @reg = io.read_ui8
      @extra = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_ui8 @debug_type
      io.write_u30 @index
      io.write_ui8 @reg
      io.write_u30 @extra
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "debug"
      @debug = true
    end
    def pretty_print(show_debug=false)
      return if @debug and not show_debug
      if @debug_type == 1
        yield "#{pretty_print_opname} reg #{@reg} is #{@name}"
      else
        yield "#{pretty_print_opname} #{@debug_type} #{@index} #{@reg}"
      end
    end
  end

  class ABCDebugFile < ABCOpcode
    attr_accessor :index, :filename
    Opcode = 0xf1
    def read(io)
      @index = io.read_u30
      @filename = @abc_file.strings[@index]
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "debug_file"
      @debug = true
    end
    def pretty_print(show_debug=false)
      return if @debug and not show_debug
      yield "#{pretty_print_opname} #{@filename}"
    end
  end

  class ABCDebugLine < ABCOpcode
    attr_accessor :linenum
    Opcode = 0xf0
    def read(io)
      @linenum = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @linenum
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "debug_line"
      @debug = true
    end
    def pretty_print(show_debug=false)
      return if @debug and not show_debug
      yield "#{pretty_print_opname} #{@linenum}"
    end
  end

  class ABCDecLocal < ABCOpcode
    Opcode = 0x94
    def initialize(abc_file)
      super(abc_file)
      @opname = "dec_local"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCDecLocalI < ABCOpcode
    Opcode = 0xc3
    def initialize(abc_file)
      super(abc_file)
      @opname = "dec_local_i"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCDecrement < ABCOpcode
    Opcode = 0x93
    def initialize(abc_file)
      super(abc_file)
      @opname = "decrement"
    end
  end

  class ABCDecrementI < ABCOpcode
    Opcode = 0xc1
    def initialize(abc_file)
      super(abc_file)
      @opname = "decrement_i"
    end
  end

  class ABCDeleteProperty < ABCOpcode
    Opcode = 0x6a
    def initialize(abc_file)
      super(abc_file)
      @opname = "delete_property"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCDivide < ABCOpcode
    Opcode = 0xa3
    def initialize(abc_file)
      super(abc_file)
      @opname = "divide"
    end
  end

  class ABCDup < ABCOpcode
    Opcode = 0x2a
    def initialize(abc_file)
      super(abc_file)
      @opname = "dup"
    end
  end

  class ABCDxNs < ABCOpcode
    Opcode = 0x06
    def initialize(abc_file)
      super(abc_file)
      @opname = "dx_ns"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCDxNsLate < ABCOpcode
    Opcode = 0x07
    def initialize(abc_file)
      super(abc_file)
      @opname = "dx_ns_late"
    end
  end

  class ABCEquals < ABCOpcode
    Opcode = 0xab
    def initialize(abc_file)
      super(abc_file)
      @opname = "equals"
    end
  end

  class ABCEscXAttr < ABCOpcode
    Opcode = 0x72
    def initialize(abc_file)
      super(abc_file)
      @opname = "exc_xattr"
    end
  end

  class ABCEscXElem < ABCOpcode
    Opcode = 0x71
    def initialize(abc_file)
      super(abc_file)
      @opname = "esc_xelem"
    end
  end

  class ABCFindProperty < ABCOpcode
    attr_accessor :index, :property
    Opcode = 0x5e
    def read(io)
      @index = io.read_u30
      @property = @abc_file.multinames[@index]
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "find_property"
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@property}"
    end
  end

  class ABCFindPropStrict < ABCOpcode
    attr_accessor :index
    Opcode = 0x5d
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "find_prop_strict"
      @index = index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property}"
    end
  end

  class ABCGetDescendants < ABCOpcode
    Opcode = 0x59
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_descendants"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCGetGlobalScope < ABCOpcode
    Opcode = 0x64
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_global_scope"
    end
  end

  class ABCGetGlobalSlot < ABCOpcode
    Opcode = 0x6e
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_global_slot"
    end
    def read(io)
      @slot_index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @slot_index
    end
  end

  class ABCGetLex < ABCOpcode
    attr_accessor :index
    Opcode = 0x60
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "get_lex"
      @index = index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property}"
    end
  end

  class ABCGetLocal < ABCOpcode
    Opcode = 0x62
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_local"
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCGetLocal0 < ABCOpcode
    Opcode = 0xd0
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_local_0"
    end
  end

  class ABCGetLocal1 < ABCOpcode
    Opcode = 0xd1
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_local_1"
    end
  end

  class ABCGetLocal2 < ABCOpcode
    Opcode = 0xd2
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_local_2"
    end
  end

  class ABCGetLocal3 < ABCOpcode
    Opcode = 0xd3
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_local_3"
    end
  end

  class ABCGetProperty < ABCOpcode
    attr_accessor :index
    Opcode = 0x66
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "get_property"
      @index = index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property}"
    end
  end

  class ABCGetScopeObject < ABCOpcode
    attr_accessor :index
    Opcode = 0x65
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_scope_object"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCGetSlot < ABCOpcode
    Opcode = 0x6c
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_slot"
    end
    def read(io)
      @slot_index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @slot_index
    end
  end

  class ABCGetSuper < ABCOpcode
    Opcode = 0x04
    def initialize(abc_file)
      super(abc_file)
      @opname = "get_super"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCGreaterEquals < ABCOpcode
    Opcode = 0xb0
    def initialize(abc_file)
      super(abc_file)
      @opname = "greater_equals"
    end
  end

  class ABCGreaterThan < ABCOpcode
    Opcode = 0xaf
    def initialize(abc_file)
      super(abc_file)
      @opname = "greater_than"
    end
  end

  class ABCHasNext < ABCOpcode
    Opcode = 0x1f
    def initialize(abc_file)
      super(abc_file)
      @opname = "has_next"
    end
  end

  class ABCHasNext2 < ABCOpcode
    Opcode = 0x32
    def initialize(abc_file)
      super(abc_file)
      @opname = "has_next_2"
    end
    def read(io)
      @object_reg = io.read_ui8
      @index_reg = io.read_ui8
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_ui8 @object_reg
      io.write_ui8 @index_reg
    end
  end

  module ABCBranch
    attr_accessor :offset
    def read(io)
      @offset = io.read_s24
    end
    def write(io)
      io.write_ui8 @opcode
      io.write_s24 @offset
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@offset} to #{@op_offset+4+@offset}"
    end
  end

  class ABCIfEq < ABCOpcode
    Opcode = 0x13
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      super()
      @opname = "if_eq"
      #@opcode = Opcode
    end
  end

  class ABCIfFalse < ABCOpcode
    Opcode = 0x12
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      super()
      @opname = "if_false"
      #@opcode = Opcode
    end
  end

  class ABCIfGe < ABCOpcode
    Opcode = 0x18
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      super()
      @opname = "if_ge"
      #@opcode = Opcode
    end
  end

  class ABCIfGt < ABCOpcode
    Opcode = 0x17
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_gt"
      #@opcode = Opcode
    end
  end

  class ABCIfLe < ABCOpcode
    Opcode = 0x16
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_le"
      #@opcode = Opcode
    end
  end

  class ABCIfLt < ABCOpcode
    Opcode = 0x15
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_lt"
      #@opcode = Opcode
    end
  end

  class ABCIfNge < ABCOpcode
    Opcode = 0x0f
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_nge"
      #@opcode = Opcode
    end
  end

  class ABCIfNgt < ABCOpcode
    Opcode = 0x0e
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_ngt"
      #@opcode = Opcode
    end
  end

  class ABCIfNle < ABCOpcode
    Opcode = 0x0d
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_nle"
      #@opcode = Opcode
    end
  end

  class ABCIfNlt < ABCOpcode
    Opcode = 0x0c
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_nlt"
      #@opcode = Opcode
    end
  end

  class ABCIfNe < ABCOpcode
    Opcode = 0x14
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_ne"
      #@opcode = Opcode
    end
  end

  class ABCIfStrictEq < ABCOpcode
    Opcode = 0x19
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_strict_eq"
      #@opcode = Opcode
    end
  end

  class ABCIfStrictNe < ABCOpcode
    Opcode = 0x1a
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_strict_ne"
      #@opcode = Opcode
    end
  end

  class ABCIfTrue < ABCOpcode
    Opcode = 0x11
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "if_true"
      #@opcode = Opcode
    end
  end

  class ABCIn < ABCOpcode
    Opcode = 0xb4
    def initialize(abc_file)
      super(abc_file)
      @opname = "in"
    end
  end

  class ABCIncLocal < ABCOpcode
    Opcode = 0x92
    def initialize(abc_file)
      super(abc_file)
      @opname = "inc_local"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCIncLocalI < ABCOpcode
    Opcode = 0xc2
    def initialize(abc_file)
      super(abc_file)
      @opname = "inc_local_i"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCIncrement < ABCOpcode
    Opcode = 0x91
    def initialize(abc_file)
      super(abc_file)
      @opname = "increment"
    end
  end

  class ABCIncrementI < ABCOpcode
    Opcode = 0xc0
    def initialize(abc_file)
      super(abc_file)
      @opname = "increment_i"
    end
  end

  class ABCInitProperty < ABCOpcode
    attr_accessor :index
    Opcode = 0x68
    def initialize(abc_file)
      super(abc_file)
      @opname = "init_property"
    end
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property}"
    end
  end

  class ABCInstanceOf < ABCOpcode
    Opcode = 0xb1
    def initialize(abc_file)
      super(abc_file)
      @opname = "instance_of"
    end
  end

  class ABCIsType < ABCOpcode
    Opcode = 0xb2
    def initialize(abc_file)
      super(abc_file)
      @opname = "is_type"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCIsTypeLate < ABCOpcode
    Opcode = 0xb3
    def initialize(abc_file)
      super(abc_file)
      @opname = "is_type_late"
    end
  end

  class ABCJump < ABCOpcode
    Opcode = 0x10
    include ABCBranch
    def initialize(abc_file)
      super(abc_file)
      @opname = "jump"
    end
  end

  class ABCKill < ABCOpcode
    Opcode = 0x08
    def initialize(abc_file)
      super(abc_file)
      @opname = "kill"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCLabel < ABCOpcode
    Opcode = 0x09
    def initialize(abc_file)
      super(abc_file)
      @opname = "abc_label"
    end
  end

  class ABCLessEquals < ABCOpcode
    Opcode = 0xae
    def initialize(abc_file)
      super(abc_file)
      @opname = "less_equals"
    end
  end

  class ABCLessThan < ABCOpcode
    Opcode = 0xad
    def initialize(abc_file)
      super(abc_file)
      @opname = "less_than"
    end
  end

  class ABCLookupSwitch < ABCOpcode
    Opcode = 0x1b
    def initialize(abc_file)
      super(abc_file)
      @opname = "lookup_switch"
    end
    def read(io)
      @default_offset = io.read_s24
      @case_count = io.read_u30
      @case_offsets = []
      1.upto(@case_count+1) do
        @case_offsets << io.read_s24
      end
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_s24 @default_offset
      io.write_u30 @case_offsets.length-1
      @case_offsets.each { |o| io.write_s24 o }
    end
  end

  class ABCLShift < ABCOpcode
    Opcode = 0xa5
    def initialize(abc_file)
      super(abc_file)
      @opname = "l_shift"
    end
  end

  class ABCModulo < ABCOpcode
    Opcode = 0xa4
    def initialize(abc_file)
      super(abc_file)
      @opname = "modulo"
    end
  end

  class ABCMultiply < ABCOpcode
    Opcode = 0xa2
    def initialize(abc_file)
      super(abc_file)
      @opname = "multiply"
    end
  end

  class ABCMultiplyI < ABCOpcode
    Opcode = 0xc7
    def initialize(abc_file)
      super(abc_file)
      @opname = "multiply_i"
    end
  end

  class ABCNegate < ABCOpcode
    Opcode = 0x90
    def initialize(abc_file)
      super(abc_file)
      @opname = "negate"
    end
  end

  class ABCNegateI < ABCOpcode
    Opcode = 0xc4
    def initialize(abc_file)
      super(abc_file)
      @opname = "negate_i"
    end
  end

  class ABCNewActivation < ABCOpcode
    Opcode = 0x57
    def initialize(abc_file)
      super(abc_file)
      @opname = "new_activation"
    end
  end

  class ABCNewArray < ABCOpcode
    Opcode = 0x56
    def initialize(abc_file)
      super(abc_file)
      @opname = "new_array"
    end
    def read(io)
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @arg_count
    end
  end

  class ABCNewCatch < ABCOpcode
    Opcode = 0x5a
    def initialize(abc_file)
      super(abc_file)
      @opname = "new_catch"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  # Scope must have scopes of all base classes before calling
  class ABCNewClass < ABCOpcode
    attr_accessor :index
    Opcode = 0x58
    def initialize(abc_file)
      super(abc_file)
      @opname = "new_class"
    end
    def clazz
      @abc_file.classes[@index] if @abc_file and @index
    end
    def instance
      @abc_file.instances[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCNewFunction < ABCOpcode
    attr_accessor :index
    Opcode = 0x40
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "new_function"
      @index = index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@index}"
    end
  end

  class ABCNewObject < ABCOpcode
    Opcode = 0x55
    def initialize(abc_file)
      super(abc_file)
      @opname = "new_object"
    end
    def read(io)
      @arg_count = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @arg_count
    end
  end

  class ABCNextName < ABCOpcode
    Opcode = 0x1e
    def initialize(abc_file)
      super(abc_file)
      @opname = "next_name"
    end
  end

  class ABCNextValue < ABCOpcode
    Opcode = 0x23
    def initialize(abc_file)
      super(abc_file)
      @opname = "next_value"
    end
  end

  class ABCNop < ABCOpcode
    Opcode = 0x02
    def initialize(abc_file)
      super(abc_file)
      @opname = "nop"
    end
  end

  class ABCNot < ABCOpcode
    Opcode = 0x96
    def initialize(abc_file)
      super(abc_file)
      @opname = "not"
    end
  end

  class ABCPop < ABCOpcode
    Opcode = 0x29
    def initialize(abc_file)
      super(abc_file)
      @opname = "pop"
    end
  end

  class ABCPopScope < ABCOpcode
    Opcode = 0x1d
    def initialize(abc_file)
      super(abc_file)
      @opname = "pop_scope"
    end
  end

  class ABCPushByte < ABCOpcode
    attr_accessor :value
    Opcode = 0x24
    def read(io)
      @value = io.read_ui8
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_ui8 @value
    end
    def initialize(abc_file, value=nil)
      super(abc_file)
      @opname = "push_byte"
      @value = value
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@value}"
    end
  end

  class ABCPushDouble < ABCOpcode
    Opcode = 0x2f
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_double"
    end
    def double
      @abc_file.doubles[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{double} (index #{@index})"
    end
  end

  class ABCPushFalse < ABCOpcode
    Opcode = 0x27
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_false"
    end
  end

  class ABCPushInt < ABCOpcode
    attr_accessor :index
    Opcode = 0x2d
    def value
      @abc_file.ints[@index] if @abc_file and @index
    end
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "push_int"
      @index = index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{value}"
    end
  end

  class ABCPushNamespace < ABCOpcode
    Opcode = 0x31
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_namespace"
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
  end

  class ABCPushNaN < ABCOpcode
    Opcode = 0x28
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_nan"
    end
  end

  class ABCPushNull < ABCOpcode
    Opcode = 0x20
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_null"
    end
  end

  class ABCPushScope < ABCOpcode
    Opcode = 0x30
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_scope"
    end
  end

  class ABCPushShort < ABCOpcode
    attr_accessor :value
    Opcode = 0x25
    def initialize(abc_file, value=nil)
      super(abc_file)
      @opname = "push_short"
      @value = value
    end
    def read(io)
      @value = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @value
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@value}"
    end
  end

  class ABCPushString < ABCOpcode
    attr_accessor :index
    Opcode = 0x2c
    def string
      @abc_file.strings[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "push_string"
      @index = index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{string}"
    end
  end

  class ABCPushTrue < ABCOpcode
    Opcode = 0x26
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_true"
    end
  end

  class ABCPushUInt < ABCOpcode
    Opcode = 0x2e
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_uint"
    end
  end

  class ABCPushUndefined < ABCOpcode
    Opcode = 0x21
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_undefined"
    end
  end

  class ABCPushWith < ABCOpcode
    Opcode = 0x1c
    def initialize(abc_file)
      super(abc_file)
      @opname = "push_with"
    end
  end

  class ABCReturnValue < ABCOpcode
    Opcode = 0x48
    def initialize(abc_file)
      super(abc_file)
      @opname = "return_value"
    end
  end

  class ABCReturnVoid < ABCOpcode
    Opcode = 0x47
    def initialize(abc_file)
      super(abc_file)
      @opname = "return_void"
    end
  end

  class ABCRShift < ABCOpcode
    Opcode = 0xa6
    def initialize(abc_file)
      super(abc_file)
      @opname = "r_shift"
    end
  end

  class ABCSetLocal < ABCOpcode
    Opcode = 0x63
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_local"
    end
  end

  class ABCSetLocal0 < ABCOpcode
    Opcode = 0xd4
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_local_0"
    end
  end

  class ABCSetLocal1 < ABCOpcode
    Opcode = 0xd5
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_local_1"
    end
  end

  class ABCSetLocal2 < ABCOpcode
    Opcode = 0xd6
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_local_2"
    end
  end

  class ABCSetLocal3 < ABCOpcode
    Opcode = 0xd7
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_local_3"
    end
  end

  class ABCSetGlobalSlot < ABCOpcode
    Opcode = 0x6f
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_global_slot"
    end
    def read(io)
      @slot_index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @slot_index
    end
  end

  class ABCSetProperty < ABCOpcode
    attr_accessor :index
    Opcode = 0x61
    def initialize(abc_file, index=nil)
      super(abc_file)
      @opname = "set_property"
      @index = index
    end
    def property
      @abc_file.multinames[@index] if @abc_file and @index
    end
    def read(io)
      @index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{property}"
    end
  end

  class ABCSetSlot < ABCOpcode
    Opcode = 0x6d
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_slot"
    end
    def read(io)
      @slot_index = io.read_u30
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @slot_index
    end
  end

  class ABCSetSuper < ABCOpcode
    Opcode = 0x05
    def initialize(abc_file)
      super(abc_file)
      @opname = "set_super"
    end
    def read(io)
      @index = io.read_u30
      @property = @abc_file.multinames[@index]
    end
    def write(io)
      io.write_ui8 Opcode
      io.write_u30 @index
    end
    def pretty_print(show_debug=false)
      yield "#{pretty_print_opname} #{@property}"
    end
  end

  class ABCStrictEquals < ABCOpcode
    Opcode = 0xac
    def initialize(abc_file)
      super(abc_file)
      @opname = "strict_equals"
    end
  end

  class ABCSubtract < ABCOpcode
    Opcode = 0xa1
    def initialize(abc_file)
      super(abc_file)
      @opname = "subtract"
    end
  end

  class ABCSubtractI < ABCOpcode
    Opcode = 0xc6
    def initialize(abc_file)
      super(abc_file)
      @opname = "subtract_i"
    end
  end

  class ABCSwap < ABCOpcode
    Opcode = 0x2b
    def initialize(abc_file)
      super(abc_file)
      @opname = "swap"
    end
  end

  class ABCThrow < ABCOpcode
    Opcode = 0x03
    def initialize(abc_file)
      super(abc_file)
      @opname = "throw"
    end
  end

  class ABCTypeOf < ABCOpcode
    Opcode = 0x95
    def initialize(abc_file)
      super(abc_file)
      @opname = "type_of"
    end
  end

  class ABCURShift < ABCOpcode
    Opcode = 0xa7
    def initialize(abc_file)
      super(abc_file)
      @opname = "ur_shift"
    end
  end

  class ABCCode
    attr_accessor :codes
    def self.new_from_io(io, abc_file=nil)
      n = ABCCode.new(abc_file)
      n.read(io)
    end
    def initialize(abc_file=nil)
      @codes = []
      @abc_file = abc_file
    end
    def read(io)
      start = io.pos
      while true
        offset = io.pos
        op = parse_command(io)
        break if not op
        op.op_offset = offset-start
        @codes << op
      end

      self
    end
    def to_s
      io = StringSwfIO.new
      write(io)
      io.rewind
      io.read
    end
    def write(io)
      @codes.each do |code|
        code.write(io)
      end

      self
    end
    def parse_command(io)
      byte = io.read_ui8
      return false if not byte

      op_class = ABCOpcode.get_code(byte)
      raise "No opcode defined for #{byte.to_s(16)} at #{io.pos}." if not op_class
      op = op_class.new(@abc_file)
      op.read(io)
      op
    end
    def pretty_print(show_debug=false)
      #@codes.each do |code|
      0.upto(@codes.length-1) do |i|
        codes[i].pretty_print(show_debug) do |s|
          idx = sprintf("%5d", i)
          Kernel.puts(idx+s)
        end
      end
    end
  end

end
