#!/usr/bin/ruby

require 'redsun/stringio'
require 'redsun/opcodes'

module RedSun

  module ABC


    class ABCFile
      attr_accessor :minor_version, :major_version
      attr_accessor :constant_pool
      attr_accessor :abc_methods
      attr_accessor :metadatas
      attr_accessor :instances, :classes
      attr_accessor :scripts
      attr_accessor :method_bodies

      Int                = 0x03
      Uint               = 0x04
      Double             = 0x06
      Utf8               = 0x01
      True               = 0x0B
      False              = 0x0A
      Null               = 0x0C
      Undefined          = 0x00

      def self.pp_yarv(vm, indent="")
        intro_step = 0
        puts("#{indent}[")
        indent = indent + "  "
        vm.each do |i|
          if intro_step <= 10
            case intro_step
            when 0,5,7
              print("#{indent}#{i.inspect}, ")
            when 1..2,8..9
              print("#{i.inspect}, ")
            when 4
              puts("#{indent}#{i.inspect},")
            when 3..4,6,10
              puts("#{i.inspect},")
            end
            intro_step = intro_step+1
          else
            pp_yarv_ops(i, indent)
          end
        end
        puts("#{indent}]")
      end

      def self.pp_yarv_ops(vm, indent="")
        puts("#{indent}[")
        indent = indent + "  "
        vm.each do |i|
          case i.class.name
          when "Fixnum"
            puts("#{indent}#{i.inspect},")
          when "Array"
            case i[0]
            when :defineclass
              puts("#{indent}[#{i[0].inspect}, #{i[1].inspect},")
              pp_yarv(i[2],indent)
              puts("#{indent}]")
            when :definemethod
              puts("#{indent}[#{i[0].inspect}, #{i[1].inspect},")
              pp_yarv(i[2],indent)
              puts("#{indent}]")
            when :send
              if i[3]
                puts("#{indent}[#{i[0].inspect}, #{i[1].inspect},#{i[2].inspect},")
                pp_yarv(i[3],indent)
                puts("#{indent}#{i[4].inspect},#{i[5].inspect}]")
              else
                puts("#{indent}#{i.inspect},")
              end
            else
              puts("#{indent}#{i.inspect},")
            end
          else
            puts("#{indent}#{i.inspect},")
          end
        end
        puts("#{indent}]")
      end

      def initialize
        clear_arrays
        setup_flash_hierarchy()

        # defaults
        @minor_version = 16
        @major_version = 46
      end

      def clear_arrays
        @constant_pool = ConstantPool.new
        @abc_methods = []
        @metadatas = []
        @instances = []
        @classes = []
        @scripts = []
        @method_bodies = []
      end

      def find_method(name)
        abc_methods = @abc_methods.select { |m| m.name == name }
        return nil if abc_methods.length == 0
        return abc_methods[0] if abc_methods.length == 1
        return abc_methods
      end

      def find_instance(name, ns=nil)
        instances = @instances.select do |c|
          c.name.name == name and (not ns or c.name.ns.name == ns)
        end
        return nil if instances.length == 0
        return instances[0] if instances.length == 1
        return instances
      end

      def uints
        @constant_pool.uints
      end

      def ints
        @constant_pool.ints
      end

      def doubles
        @constant_pool.doubles
      end

      def strings
        @constant_pool.strings
      end

      def namespaces
        @constant_pool.namespaces
      end

      def ns_sets
        @constant_pool.ns_sets
      end

      def multinames
        @constant_pool.multinames
      end


    end

    class Method
      NeedArguments  = 0x01
      NeedActivation = 0x02
      NeedRest       = 0x04
      HasOptional    = 0x08
      SetDxns        = 0x40
      HasParamNames  = 0x80


      attr_accessor :return_type_index, :param_types
      attr_accessor :name_index

      attr_accessor :need_arguments, :need_activation, :need_rest
      attr_accessor :has_optional, :set_dxns, :has_param_names

      attr_accessor :options, :param_names

      attr_accessor :body

      def self.new_from_io(io, abc_file=nil)
        ns = Method.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        @abc_file = abc_file
        clear_arrays

        @need_arguments   = false
        @need_activation  = false
        @need_rest        = false
        @has_optional     = false
        @set_dxns         = false
        @has_param_names  = false
      end

      def clear_arrays
        @param_types = []
        @options = []
        @param_names = []
      end

      def inspect
        "#<Method:0x#{object_id.to_s(16)} @name_index=#{@name_index} @name=#{name.inspect} @return_type_index=#{@return_type_index} @return_type=#{return_type} @param_types=#{@param_types} @param_names=#{@param_names} @options=#{@options} @need_arguments=#{@need_arguments} @need_activation=#{@need_activation} @need_rest=#{@need_rest} @has_optional=#{@has_optional} @set_dxns=#{@set_dxns} @has_param_names=#{@has_param_names} @body=#{@body}>"
      end

      def return_type
        @abc_file.multinames[@return_type_index] if @abc_file and @return_type_index
      end

      def name
        @abc_file.strings[@name_index] if @abc_file and @name_index
      end

      def read_from_io(io)
        clear_arrays

        param_count = io.read_u30
        @return_type_index = io.read_u30
        1.upto(param_count) do
          @param_types << io.read_u30
        end
        @name_index = io.read_u30
        flags = io.read_ui8

        @need_arguments   = flags & NeedArguments  != 0
        @need_activation  = flags & NeedActivation != 0
        @need_rest        = flags & NeedRest       != 0
        @has_optional     = flags & HasOptional    != 0
        @set_dxns         = flags & SetDxns        != 0
        @has_param_names  = flags & HasParamNames  != 0

        if @has_optional
          option_count = io.read_u30
          1.upto(option_count) do
            @options << MethodOptionDetail.new(io, @abc_file)
          end
        end

        if @has_param_names
          1.upto(param_count) do
            @param_names << io.read_u30
          end
        end

        self
      end

      def write_to_io(io)
        io.write_u30 @param_types.length
        io.write_u30 @return_type_index

        @param_types.each { |v| io.write_u30 v }

        io.write_u30 @name_index
        flags = 0
        flags |= NeedArguments  if @need_arguments
        flags |= NeedActivation if @need_activation
        flags |= NeedRest       if @need_rest
        flags |= HasOptional    if @has_optional
        flags |= SetDxns        if @set_dxns
        flags |= HasParamNames  if @has_param_names
        io.write_ui8 flags

        if @has_optional
          io.write_u30 @options.length
          @options.each { |o| o.write_to_io(io) }
        end

        self
      end

      def pretty_print(show_debug=false)
        body.code.pretty_print(show_debug) if body and body.code
      end
    end

    class MethodOptionDetail
      attr_accessor :val, :kind
      def initialize(io=nil, abc_file=nil)
        read_from_io(io, abc_file) if io
      end
      def read_from_io(io, abc_file)
        @val = io.read_u30
        @kind = io.read_ui8
      end
      def write_to_io(io)
        io.write_u30 @val
        io.write_ui8 @kind
      end
    end

    class Metadata
      attr_accessor :name_index, :name, :items
      def initialize(io=nil, abc_file=nil)
        if io
          read_from_io(io, abc_file)
        else
          clear_arrays
        end
      end

      def clear_arrays
        @items = []
      end

      def read_from_io(io, abc_file)
        clear_arrays

        @name_index = io.read_u30
        @name = abc_file.strings[@name_index]
        item_count = io.read_u30
        1.upto(item_count) do
          @items << MetadataItem.new(io, abc_file)
        end

        self
      end

      def write_to_io(io)
        io.write_u30 @name_index
        io.write_u30 @items.length
        @items.each { |i| i.write_to_io io }

        self
      end
    end

    class MetadataItem
      attr_accessor :key, :value
      def initialize(io=nil, abc_file=nil)
        read_from_io(io, abc_file) if io
      end

      def read_from_io(io, abc_file)
        @key = io.read_u30
        @value = io.read_u30

        self
      end

      def write_to_io(io)
        io.write_u30 @key
        io.write_u30 @value

        self
      end
    end

    class Instance
      attr_accessor :name_index, :super_name_index
      attr_accessor :abc_class
      attr_accessor :flags
      attr_accessor :protected_namespace_index
      attr_accessor :interface_indices
      attr_accessor :iinit_index
      attr_accessor :traits

      Sealed = 0x01
      Final = 0x02
      Interface = 0x03
      ProtectedNamespace = 0x08

      def self.new_from_io(io=nil, abc_file=nil)
        ns = Instance.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        clear_arrays
        @abc_file = abc_file
      end

      def clear_arrays
        @interface_indices = []
        @traits = []
      end

      def inspect
        "#<Instance:0x#{object_id.to_s(16)} @name_index=#{@name_index} @name=\"#{name}\" @super_name_index=#{@super_name_index} @super_name=\"#{super_name}\" @protected_namespace_index=#{@protected_namespace_index} @flags=#{@flags} @protected_namespace=\"#{protected_namespace}\" @interface_indices=#{@interface_indices} @iinit_index=#{@iinit_index} @traits=#{@traits}>"
      end

      def method_traits
        traits.select { |t| t.data.class == TraitMethod }
      end

      def name
        @abc_file.multinames[@name_index] if @abc_file and @name_index
      end

      def super_name
        @abc_file.multinames[@super_name_index] if @abc_file and @super_name_index
      end

      def protected_namespace
        @abc_file.namespaces[@protected_namespace_index] if @abc_file and @protected_namespace_index
      end

      def interfaces
        return [] if not @abc_file or not @interface_indices
        @interface_indices.map { |index| @abc_file.multinames[index] }
      end

      def iinit
        @abc_file.abc_methods[@iinit_index] if @abc_file and @iinit_index
      end

      def read_from_io(io)
        clear_arrays

        @name_index = io.read_u30
        @super_name_index = io.read_u30
        @flags = io.read_ui8

        if @flags & ProtectedNamespace != 0
          @protected_namespace_index = io.read_u30
        end

        interface_count = io.read_u30
        1.upto(interface_count) do
          interface_index = io.read_u30
          @interface_indices << interface_index
        end

        @iinit_index = io.read_u30
        trait_count = io.read_u30
        1.upto(trait_count) do
          @traits << Trait.new_from_io(io, @abc_file)
        end

        self
      end

      def write_to_io(io)
        io.write_u30 @name_index
        io.write_u30 @super_name_index
        io.write_ui8 @flags

        if @flags & ProtectedNamespace != 0
          io.write_u30 @protected_namespace_index
        end

        io.write_u30 @interface_indices.length
        @interface_indices.each { |v| io.write_u30(v) }

        io.write_u30 @iinit_index

        io.write_u30 @traits.length
        @traits.each { |trait| trait.write_to_io(io) }

        self
      end
    end

    class Trait
      attr_accessor :name_index, :type, :data
      attr_accessor :has_metadata, :final, :override
      attr_accessor :metadatas
      SlotId = 0
      MethodId = 1
      GetterId = 2
      SetterId = 3
      ClassId = 4
      FunctionId = 5
      ConstId = 6

      Final    = 0x01
      Override = 0x02
      Metadata = 0x04

      def self.new_from_io(io, abc_file=nil)
        ns = Trait.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        @abc_file = abc_file
        clear_arrays

        @has_metadata = false
        @final = false
        @override = false
      end

      def clear_arrays
        @metadatas = []
      end

      def name
        @abc_file.constant_pool.multinames[@name_index] if @abc_file and @name_index
      end

      def read_from_io(io)
        clear_arrays

        @name_index = io.read_u30
        kind = io.read_ui8
        @type = kind & 0x0F
        attributes = (kind & 0xF0) >> 4

        @has_metadata = attributes & Metadata != 0
        @final        = attributes & Final    != 0
        @override     = attributes & Override != 0


        case @type
        when SlotId, ConstId
          @data = TraitSlot.new_from_io(io, @abc_file)
        when ClassId
          @data = TraitClass.new_from_io(io, @abc_file)
        when FunctionId
          @data = TraitFunction.new_from_io(io, @abc_file)
        when MethodId, GetterId, SetterId
          @data = TraitMethod.new_from_io(io, @abc_file)
        else
          raise "bad trait value #{kind}."
        end

        if @has_metadata
          metadata_count = io.read_u30
          1.upto(metadata_count) do
            @metadatas << io.read_u30
          end
        end

        self
      end
      def write_to_io(io)
        io.write_u30(@name_index)

        attributes = 0
        attributes |= Metadata if @has_metadata
        attributes |= Final    if @final
        attributes |= Override if @override

        io.write_ui8((attributes << 4) | @type)

        case @type
        when SlotId, ConstId
          @data.write_to_io(io)
        when ClassId
          @data.write_to_io(io)
        when FunctionId
          @data.write_to_io(io)
        when MethodId, GetterId, SetterId
          @data.write_to_io(io)
        end

        if @has_metadata
          io.write_u30(@metadatas.length)
          @metadatas.each { |m| io.write_u30(m) }
        end

        self
      end
    end

    class TraitData
      def self.new_from_io(io, abc_file=nil)
        ns = self.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        @abc_file = abc_file
      end
      def read_from_io(io)
        self
      end
      def write_to_io(io)
        self
      end
    end

    class TraitSlot < TraitData
      attr_accessor :slot_id, :type_name_index
      attr_accessor :vindex, :vkind
      def type_name
        @abc_file.multinames[@type_name_index] if @abc_file and @type_name_index
      end
      def read_from_io(io)
        @slot_id = io.read_u30
        @type_name_index = io.read_u30
        @vindex = io.read_u30
        @vkind = io.read_ui8 unless @vindex == 0

        self
      end
      def write_to_io(io)
        io.write_u30 @slot_id
        io.write_u30 @type_name_index
        io.write_u30 @vindex
        io.write_ui8 @vkind unless @vindex == 0

        self
      end
    end

    class TraitClass < TraitData
      attr_accessor :slot_id, :class_index
      def clazz
        @abc_file.classes[@class_index] if @abc_file and @class_index
      end
      def read_from_io(io)
        @slot_id = io.read_u30
        @class_index = io.read_u30

        self
      end
      def write_to_io(io)
        io.write_u30 @slot_id
        io.write_u30 @class_index

        self
      end
    end

    class TraitFunction < TraitData
      attr_accessor :slot_id, :function_index
      def function
        @abc_file.abc_methods[@function_index] if @abc_file and @function_index
      end
      def read_from_io(io)
        @slot_id = io.read_u30
        @function_index = io.read_u30

        self
      end
      def write_to_io(io)
        io.write_u30 @slot_id
        io.write_u30 @function_index

        self
      end
    end

    class TraitMethod < TraitData
      attr_accessor :disp_id, :method_index
      def method
        @abc_file.abc_methods[@method_index] if @abc_file and @method_index
      end
      def read_from_io(io)
        @disp_id = io.read_u30
        @method_index = io.read_u30

        self
      end
      def write_to_io(io)
        io.write_u30 @disp_id
        io.write_u30 @method_index

        self
      end
    end

    class Class
      attr_accessor :cinit_index, :traits

      def self.new_from_io(io, abc_file=nil)
        ns = Class.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        clear_arrays
        @abc_file = abc_file
      end

      def clear_arrays
        @traits = []
      end

      def inspect
        "#<Class:0x#{object_id.to_s(16)} @cinit_index=#{@cinit_index} @traits=#{@traits}>"
      end

      def cinit
        @abc_file.abc_methods[@cinit_index] if @abc_file and @cinit_index
      end

      def read_from_io(io)
        clear_arrays

        @cinit_index = io.read_u30
        trait_count = io.read_u30
        1.upto(trait_count) do
          @traits << Trait.new_from_io(io, @abc_file)
        end
        self
      end
      def write_to_io(io)
        io.write_u30 @cinit_index

        io.write_u30 @traits.length
        @traits.each { |t| t.write_to_io io }

        self
      end
    end

    class Script
      attr_accessor :init_index, :traits

      def self.new_from_io(io, abc_file=nil)
        ns = Script.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        @abc_file = abc_file
        clear_arrays
      end

      def clear_arrays
        @traits = []
      end

      def init
        @abc_file.abc_methods[@init_index] if @abc_file and @init_index
      end

      def read_from_io(io)
        clear_arrays

        @init_index = io.read_u30

        trait_count = io.read_u30
        1.upto(trait_count) do
          traits << Trait.new_from_io(io, @abc_file)
        end

        self
      end
      def write_to_io(io)
        io.write_u30 @init_index

        io.write_u30 @traits.length
        @traits.each { |t| t.write_to_io(io) }

        self
      end
    end

    class MethodBody
      attr_accessor :method_index
      attr_accessor :max_stack, :local_count
      attr_accessor :init_scope_depth, :max_scope_depth
      attr_accessor :code
      attr_accessor :exceptions
      attr_accessor :traits

      def self.new_from_io(io, abc_file=nil)
        ns = MethodBody.new(abc_file)
        ns.read_from_io(io)
      end

      def initialize(abc_file=nil)
        @abc_file = abc_file
        clear_arrays
      end

      def clear_arrays
        @exceptions = []
        @traits = []
        @code = Code.new(@abc_file)
      end

      def method
        @abc_file.abc_methods[@method_index] if @abc_file and @method_index
      end

      def inspect
        "#<MethodBody:0x#{object_id.to_s(16)} @method_index=#{@name_index} @max_stack=#{@max_stack} @local_count=#{@local_count} @init_scope_depth=#{@init_scope_depth} @max_scope_depth=#{@max_scope_depth} @exceptions=#{@exceptions} @traits=#{@traits} @code=\"#{@code.codes.length} opcodes\">"
      end

      def read_from_io(io)
        clear_arrays

        @method_index = io.read_u30
        method.body = self

        @max_stack = io.read_u30
        @local_count = io.read_u30
        @init_scope_depth = io.read_u30
        @max_scope_depth = io.read_u30

        code_length = io.read_u30
        code_data = io.read code_length

        # parse abc code
        @code = Code.new_from_io(StringSwfIO.new(code_data), @abc_file)

        exception_count = io.read_u30
        1.upto(exception_count) do
          @exceptions << Exception.new(io, @abc_file)
        end

        trait_count = io.read_u30
        1.upto(trait_count) do
          @traits << Trait.new_from_io(io, @abc_file)
        end

        self
      end
      def write_to_io(io)
        io.write_u30 @method_index

        io.write_u30 @max_stack
        io.write_u30 @local_count
        io.write_u30 @init_scope_depth
        io.write_u30 @max_scope_depth

        code_data = @code.to_s
        io.write_u30(code_data.length)
        io.write(code_data)

        io.write_u30(@exceptions.length)
        @exceptions.each { |e| e.write_to_io io }

        io.write_u30(@traits.length)
        @traits.each { |t| t.write_to_io io }

        self
      end
    end

    class Exception
      def initialize(io=nil, abc_file=nil)
        read_from_io(io, abc_file) if io
      end

      def read_from_io(io, abc_file)
        @from = io.read_u30
        @to = io.read_u30
        @target = io.read_u30
        @exc_type = io.read_u30
        @var_name = io.read_u30

        self
      end
      def write_to_io(io)
        io.write_u30(@from)
        io.write_u30(@to)
        io.write_u30(@target)
        io.write_u30(@exc_type)
        io.write_u30(@var_name)

        self
      end
    end

    class ConstantPool
      attr_accessor :ints
      attr_accessor :uints
      attr_accessor :doubles
      attr_accessor :strings
      attr_accessor :namespaces
      attr_accessor :ns_sets
      attr_accessor :multinames

      def initialize io=nil
        if io
          read_from_io(io)
        else
          clear_arrays
        end
      end

      def clear_arrays
        @ints = [nil]
        @uints = [nil]
        @doubles = [nil]
        @strings = [nil]
        @namespaces = [nil]
        @ns_sets = [nil]
        @multinames = [Multiname.new(nil,nil,nil,nil,self)]
      end

      def find_arr(value, arr)
        arr.index(value)
      end

      def find_int(value)       find_arr(value, @ints)       end
      def find_uint(value)      find_arr(value, @uints)      end
      def find_double(value)    find_arr(value, @doubles)    end
      def find_string(value)    find_arr(value, @strings)    end
      def find_namespace(value) find_arr(value, @namespaces) end
      def find_ns_set(value)    find_arr(value, @ns_sets)    end
      def find_multiname(value) find_arr(value, @multinames) end

    end

    class Namespace
      attr_accessor :kind, :name_index

      NamespaceC         = 0x08
      PackageNamespace   = 0x16
      PackageInternalNs  = 0x17
      ProtectedNamespace = 0x18
      ExplicitNamespace  = 0x19
      StaticProtectedNs  = 0x1A
      PrivateNs          = 0x05

      def name
        @constant_pool.strings[@name_index] if @constant_pool and @name_index
      end
      def self.new_from_io(io=nil, constant_pool=nil)
        ns = Namespace.new(nil,nil,constant_pool)
        ns.read_from_io(io)
      end
      def self.kind_to_s(kind)
        case kind
        when Namespace::NamespaceC
          "Namespace"
        when Namespace::PackageNamespace
          "PackageNamespace"
        when Namespace::PackageInternalNs
          "PackageInternalNs"
        when Namespace::ProtectedNamespace
          "ProtectedNamespace"
        when Namespace::ExplicitNamespace
          "ExplicitNamespace"
        when Namespace::StaticProtectedNs
          "StaticProtectedNs"
        when Namespace::PrivateNs
          "PrivateNs"
        end
      end
      def initialize(kind=nil, name_index=nil, constant_pool=nil)
        @kind = kind
        @name_index = name_index
        @constant_pool = constant_pool
      end

      def inspect
        "#<Namespace:0x#{object_id.to_s(16)} @kind=#{Namespace.kind_to_s(@kind)} @name_index=#{@name_index} @name=#{name.inspect}>"
      end

      def read_from_io(io)
        @kind = io.read_ui8
        @name_index = io.read_u30
        self
      end

      def write_to_io(io)
        io.write_ui8 @kind
        io.write_u30 @name_index
      end

      def to_s
        "(#{Namespace.kind_to_s(@kind)})#{name}"
      end

      def ==(o)
        @kind == o.kind and @name_index == o.name_index
      end
    end

    class NsSet
      attr_accessor :ns_indices

      def self.new_from_io(io=nil, constant_pool=nil)
        ns = NsSet.new(nil,constant_pool)
        ns.read_from_io(io)
      end

      def initialize(ns_indices=nil, constant_pool=nil)
        @ns_indices = ns_indices
        @constant_pool = constant_pool
      end

      def inspect
        "#<NsSet:0x#{object_id.to_s(16)} @ns_indices=#{@ns_indices}>"
      end

      def to_s
        "<NsSet ns_indices=#{@ns_indices}>"
      end

      def ==(o)
        @ns_indices == o.ns_indices
      end

      def ns
        ns_indices.map { |index| @constant_pool.namespaces[index] }
      end

      def read_from_io(io)
        count = io.read_u30
        @ns = []
        @ns_indices = []
        1.upto(count) do
          index = io.read_u30
          @ns_indices << index
          #@ns << constant_pool.namespaces[index]
        end

        self
      end

      def write_to_io(io)
        io.write_u30 @ns_indices.length
        @ns_indices.each { |i| io.write_u30 i }

        self
      end
    end

    class Multiname
      attr_accessor :kind, :ns_index, :name_index, :ns_set_index

      MultinameQName = 0x07
      MultinameQNameA = 0x0D
      MultinameRTQName = 0x0F
      MultinameRTQNameA = 0x10
      MultinameRTQNameL = 0x11
      MultinameRTQNameLA = 0x12
      MultinameC = 0x09
      MultinameA = 0x0E
      MultinameL = 0x1B
      MultinameLA = 0x1C

      def self.new_from_io(io=nil, constant_pool=nil)
        m = Multiname.new(nil,nil,nil,nil,constant_pool)
        m.read_from_io(io)
      end
      def self.kind_to_s(kind)
        case kind
        when nil
          "Multiname-index-0"
        when Multiname::MultinameQName
          "MultinameQName"
        when Multiname::MultinameQNameA
          "MultinameQNameA"
        when Multiname::MultinameRTQName
          "MultinameRTQName"
        when Multiname::MultinameRTQNameA
          "MultinameRTQNameA"
        when Multiname::MultinameRTQNameL
          "MultinameRTQNameL"
        when Multiname::MultinameRTQNameLA
          "MultinameRTQNameLA"
        when Multiname::MultinameC
          "Multiname"
        when Multiname::MultinameA
          "MultinameA"
        when Multiname::MultinameL
          "MultinameL"
        when Multiname::MultinameLA
          "MultinameLA"
        end
      end

      def initialize(kind=nil, name_index=nil, ns_index=nil, ns_set_index=nil, constant_pool=nil)
        @kind = kind
        @name_index = name_index
        @ns_index = ns_index
        @ns_set_index = ns_set_index
        @constant_pool = constant_pool
      end

      def inspect
        "#<Multiname:0x#{object_id.to_s(16)} @kind=#{Multiname.kind_to_s(@kind)} @name_index=#{@name_index} @name=\"#{name}\" @ns_index=#{@ns_index} @ns=#{ns} @ns_set_index=#{@ns_set_index} @ns_set=#{ns_set}>"
      end

      def ==(o)
        @kind == o.kind and
          @ns_index == o.ns_index and
          @name_index == o.name_index and
          @ns_set_index == o.ns_set_index
      end

      def ns
        @constant_pool.namespaces[@ns_index] if @constant_pool and @ns_index
      end
      def name
        @constant_pool.strings[@name_index] if @constant_pool and @name_index
      end
      def ns_set
        @constant_pool.ns_sets[@ns_set_index] if @constant_pool and @ns_set_index
      end

      def read_from_io(io)
        @kind = io.read_ui8
        case @kind
        when MultinameQName, MultinameQNameA
          @ns_index = io.read_u30
          @name_index = io.read_u30
        when MultinameRTQName, MultinameRTQNameA
          @name_index = io.read_u30
        when MultinameRTQNameL, MultinameRTQNameLA
          # no data
        when MultinameC, MultinameA
          @name_index = io.read_u30
          @ns_set_index = io.read_u30
        when MultinameL, MultinameLA
          @ns_set_index = io.read_u30
        end

        self
      end

      def write_to_io(io)
        io.write_ui8 @kind
        case @kind
        when MultinameQName, MultinameQNameA
          io.write_u30 @ns_index
          io.write_u30 @name_index
        when MultinameRTQName, MultinameRTQNameA
          io.write_u30 @name_index
        when MultinameRTQNameL, MultinameRTQNameLA
          # no data
        when MultinameC, MultinameA
          io.write_u30 @name_index
          io.write_u30 @ns_set_index
        when MultinameL, MultinameLA
          io.write_u30 @ns_set_index
        end

        self
      end

      def to_s
        case @kind
        when MultinameQName, MultinameQNameA
          "(#{Multiname.kind_to_s(@kind)})#{ns}::#{name}"
        when MultinameRTQName, MultinameRTQNameA
          "(#{Multiname.kind_to_s(@kind)})stack::#{name}"
        when MultinameRTQNameL, MultinameRTQNameLA
          # no data
          "(#{Multiname.kind_to_s(@kind)})stack::stack"
        when MultinameC, MultinameA
          "(#{Multiname.kind_to_s(@kind)})Set:#{@ns_set_index}::#{name}"
        when MultinameL, MultinameLA
          "(#{Multiname.kind_to_s(@kind)})Set:#{@ns_set_index}::stack"
        end
      end
    end

  end

end
