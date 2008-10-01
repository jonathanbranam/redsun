#!/usr/bin/ruby

require 'redsun/stringio'
require 'redsun/opcodes'

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
          if i[1] == :proc
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

  def read_from_str str
    read_from_io(StringSwfIO.new(str))
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

  def read_from_io(io)
    clear_arrays

    @minor_version = io.read_ui16
    @major_version = io.read_ui16

    @constant_pool.read_from_io(io)

    method_count = io.read_u30
    #puts("Reading #{method_count} methods.")
    1.upto(method_count) do
      method = ABCMethod.new_from_io(io, self)
      @abc_methods << method
    end

    metadata_count = io.read_u30
    #puts("Reading #{metadata_count} metadatas.")
    1.upto(metadata_count) do
      metadata = ABCMetadata.new(io, self)
      @metadatas << metadata
    end

    class_count = io.read_u30
    #puts("Reading #{class_count} instances.")
    1.upto(class_count) do |i|
      #puts("Reading instance #{i}.")
      inst = ABCInstance.new_from_io(io, self)
      @instances << inst
    end
    #puts("Reading #{class_count} classes.")
    1.upto(class_count) do |i|
      c = ABCClass.new_from_io(io, self)
      @classes << c
      @instances[i-1].abc_class = c
    end

    script_count = io.read_u30
    #puts("Reading #{script_count} script.")
    1.upto(script_count) do
      script = ABCScript.new_from_io(io, self)
      @scripts << script
    end

    method_body_count = io.read_u30
    #puts("Reading #{method_body_count} method_body.")
    1.upto(method_body_count) do
      method_body = ABCMethodBody.new_from_io(io, self)
      @method_bodies << method_body
    end

  end

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

  def load_ruby(instr)
    return if instr[0] != "YARVInstructionSequence/SimpleDataFormat"
    type = instr[7]
    case type
    when :top
      load_ruby_top(instr)
    when :class
      load_ruby_class(instr)
    when :method
      load_ruby_method(instr, class_index)
    end

    self
  end

  def load_ruby_top(instr, first_class_doc=true)
    body = instr[11]
    lineno = nil
    stack = []
    class_count = 0
    body.each do |line|
      if line.is_a? Integer
        lineno = line
        next
      elsif line.is_a? Symbol
        # label ?
      elsif line.is_a? Array
        op = line[0]
        case op
        when :putnil
          stack.push(line)
        when :getinlinecache, :setinlinecache
        when :getconstant
          stack.push(line)
        when :defineclass
          class_count = class_count+1
          parent = find_parent_class(stack)
          load_ruby_class(parent, line[1], line[2], class_count==1)
        end
      end
    end
  end

  def find_parent_class(stack)
    parent = ""
    stack.reverse.each do |line|
      case line[0]
      when :getconstant
        parent = "." + parent if parent != ""
        str = line[1].to_s
        #parent = str[0].downcase + str[1..-1] + parent
        parent = str + parent
        stack.pop()
      when :putnil
        stack.pop()
        break
      end
    end
    parent
  end
  private :find_parent_class

  def load_ruby_class(parent, class_name, instr, is_doc_class=false)
    return if instr[0] != "YARVInstructionSequence/SimpleDataFormat"
    encoded_class_name = instr[5]
    class_name = encoded_class_name.match('<class:(.*)>')[1]
    class_index = new_class(class_name, parent)

    inst = instances[class_index]
    cls = classes[class_index]

    methods = []

    class_ns_set = create_class_ns_set(inst, class_index)

    body = instr[11]
    lineno = nil
    stack = []
    body.each do |line|
      if line.is_a? Integer
        lineno = line
        next
      elsif line.is_a? Symbol
        # label ?
      elsif line.is_a? Array
        op = line[0]
        case op
        when :putnil
          stack.push(line)
        when :definemethod
          stack.pop() # clear :putnil ??
          index = load_ruby_method(class_index, line[1], line[2], class_ns_set)
          if (line[1] == :initialize)
            #constructor
            inst.iinit_index = index
          else
            methods << index
          end
        end
      end
    end

    # create method to create class body and setup methods
    create_cinit(cls, methods, class_ns_set)

    # create script to create actual class
    if is_doc_class
      create_doc_class_init_script(inst, class_index)
    else
      create_class_init_script(inst, class_index)
    end
  end

  def shared_class_script_init(inst, class_index)
    scr = ABCScript.new(self)
    script_index = scripts.length
    scripts << scr

    method_index, mbody_index = create_method()
    method = @abc_methods[method_index]
    mbody = @method_bodies[mbody_index]

    method.return_type_index = 0
    method.name_index = @constant_pool.add_string("".to_sym)

    scr.init_index = method_index

    trait = ABCTrait.new(self)
    scr.traits << trait

    trait.name_index = inst.name_index
    trait.type = ABCTrait::ClassId
    trait.data = TraitClass.new(self)
    trait.data.slot_id = 1
    trait.data.class_index = class_index

    script_index
  end

  def ns_from_class_multiname(mn)
    if mn.ns.name.length > 0
      (mn.ns.name.to_s + ":" + mn.name.to_s).to_sym
    else
      mn.name
    end
  end

  def create_class_ns_set(inst, class_index)
    ns_indices = []

    ns_indices << get_ns(ABCNamespace::PrivateNs, ns_from_class_multiname(inst.name))
    ns_indices << get_ns(ABCNamespace::PrivateNs, "file.as")

    ns_indices << get_ns(ABCNamespace::PackageNamespace, inst.name.ns.name)
    ns_indices << get_ns(ABCNamespace::PackageInternalNs, inst.name.ns.name)
    ns_indices << get_ns(ABCNamespace::ProtectedNamespace, ns_from_class_multiname(inst.name))
    ns_indices << get_ns(ABCNamespace::StaticProtectedNs, ns_from_class_multiname(inst.name))

    hierarchy = get_hierarchy(inst.name).reverse
    hierarchy.each do |clz_sym|
      match = clz_sym.to_s.match(/^([\w.]+:)?(\w+)$/)
      package, name = match[1] || "", match[2]
      ns_indices << get_ns(ABCNamespace::StaticProtectedNs, package+name)
    end


    @constant_pool.add_ns_set(ABCNsSet.new(ns_indices, @constant_pool))
  end

  def create_class_init_method_body(inst, class_index, mbody)
    mbody.max_stack = 2
    mbody.local_count = 1
    mbody.init_scope_depth = 1
    # number of parent classes
    mbody.max_scope_depth = 8

    codes = mbody.code.codes

    codes << ABCGetLocal0.new(self)
    codes << ABCPushScope.new(self)

    # let caller insert opcode to get the target object
    yield codes

    hierarchy = get_hierarchy(inst.name)
    hierarchy.each do |clz_sym|
      gl = ABCGetLex.new(self)
      match = clz_sym.to_s.match(/^(?:([\w.]+):)?(\w+)$/)
      package, name = match[1] || "", match[2]
      gl.index = get_qname(name, ABCNamespace::PackageNamespace, package)
      codes << gl
      codes << ABCPushScope.new(self)
    end

    gl = ABCGetLex.new(self)
    clz_sym = hierarchy.last
    match = clz_sym.to_s.match(/^(?:([\w.]+):)?(\w+)$/)
    package, name = match[1] || "", match[2]
    gl.index = get_qname(name, ABCNamespace::PackageNamespace, package)
    codes << gl

    nc = ABCNewClass.new(self)
    nc.index = class_index
    codes << nc

    hierarchy.each do |clz|
      codes << ABCPopScope.new(self)
    end

    ip = ABCInitProperty.new(self)
    ip.index = inst.name_index
    codes << ip

    codes << ABCReturnVoid.new(self)
  end

  def setup_flash_hierarchy()
    @hierarchy = {}

    ed  = "flash.events:EventDispatcher".to_sym
    dob = "flash.display:DisplayObject".to_sym
    shp = "flash.display:Shape".to_sym
    io  = "flash.display:InteractiveObject".to_sym
    tf  = "flash.display:TextField".to_sym
    doc = "flash.display:DisplayObjectContainer".to_sym
    spr = "flash.display:Sprite".to_sym

    @hierarchy[:Object] = nil
    @hierarchy[ed] = :Object
    @hierarchy[dob] = ed
    @hierarchy[shp] = dob
    @hierarchy[io] = dob
    @hierarchy[tf] = io
    @hierarchy[doc] = io
    @hierarchy[spr] = doc
  end

  def get_hierarchy(m)
    hierarchy = []
    cur = get_parent(m)
    while cur != nil
      hierarchy.unshift(cur)
      cur = @hierarchy[cur]
    end
    hierarchy
  end

  def register_instance(inst)
    clz_sym = (inst.name.ns.name.to_s+":"+inst.name.name.to_s).to_sym
    par_sym = (inst.super_name.ns.name.to_s+":"+inst.super_name.name.to_s).to_sym
    @hierarchy[clz_sym] = par_sym
  end

  def get_parent(m)
    @hierarchy[(m.ns.name.to_s+":"+m.name.to_s).to_sym]
  end

  def create_doc_class_init_script(inst, class_index)
    script_index = shared_class_script_init(inst, class_index)
    scr = scripts[script_index]

    create_class_init_method_body(inst, class_index, scr.init.body) do |codes|
      op = ABCGetScopeObject.new(self)
      op.index = 0
      codes << op
    end
  end

  def create_class_init_script(inst, class_index)
    script_index = shared_class_script_init(inst, class_index)
    scr = scripts[script_index]

    create_class_init_method_body(inst, class_index, scr.init.body) do |codes|
      op = ABCFindPropStrict.new(self)
      # set multiname ns_set and classname
      codes << op
    end
  end

  def create_method()
    method = ABCMethod.new(self)
    method_index = @abc_methods.length
    @abc_methods << method
    mbody = ABCMethodBody.new(self)
    mbody_index = @method_bodies.length
    @method_bodies << mbody

    method.body = mbody
    mbody.method_index = method_index

    [method_index, mbody_index]
  end

  def create_cinit(cls, methods, class_ns_set)
    cinit_method_index, cinit_mbody_index = create_method()
    cinit_method = @abc_methods[cinit_method_index]
    cinit_mbody = @method_bodies[cinit_mbody_index]

    cls.cinit_index = cinit_method_index

    cinit_method.return_type_index = 0
    cinit_method.name_index = @constant_pool.add_string("".to_sym)

    cinit_mbody.max_stack = 1 if methods.empty?
    cinit_mbody.max_stack = 2 if not methods.empty?
    cinit_mbody.local_count = 1
    cinit_mbody.init_scope_depth = 0
    cinit_mbody.max_scope_depth = 1
    codes = cinit_mbody.code.codes
    codes << ABCGetLocal0.new(self)
    codes << ABCPushScope.new(self)

    prot_mn = get_multiname(:prototype, class_ns_set) if not methods.empty?
    # JPB
    methods.each do |index|
      name = @abc_methods[index].name.to_s
      name.match(/^(?:\w+\/)?(\w+)$/)
      mn = get_multiname($1, class_ns_set)
      codes << ABCGetLex.new(self, prot_mn)
      codes << ABCNewFunction.new(self, index)
      codes << ABCSetProperty.new(self, mn)
    end


    codes << ABCReturnVoid.new(self)

  end

  def load_ruby_method(class_index, method_name, instr, class_ns_set)
    return if instr[0] != "YARVInstructionSequence/SimpleDataFormat"

    inst = instances[class_index]

    method_index, mbody_index = create_method()
    method = @abc_methods[method_index]
    mbody = @method_bodies[mbody_index]

    method.return_type_index = 0
    if method_name == :initialize
      # constructor
      method.name_index = @constant_pool.add_string((inst.name.name.to_s+"/"+inst.name.name.to_s).to_sym)
    else
      method.name_index = @constant_pool.add_string((inst.name.name.to_s+"/"+method_name.to_s).to_sym)
    end

    mbody.method_index = method_index

    method.param_types = Array.new(instr[9], 0)

    mbody.max_stack = 1
    mbody.local_count = 1
    mbody.init_scope_depth = 0
    mbody.max_scope_depth = 1
    codes = mbody.code.codes
    codes << ABCGetLocal0.new(self)
    codes << ABCPushScope.new(self)

    stack_depth = 1
    scope_depth = 1
    inc_scope_depth = lambda do
      scope_depth += 1
      mbody.max_scope_depth = scope_depth if scope_depth > mbody.max_scope_depth
    end
    inc_stack = lambda do
      stack_depth += 1
      mbody.max_stack = stack_depth if stack_depth > mbody.max_stack
    end

    body = instr[11]
    lineno = nil
    stack = []
    doing_get = false

    body.each do |line|
      if line.is_a? Integer
        lineno = line
        next
      elsif line.is_a? Symbol
        # label ?
      elsif line.is_a? Array
        op = line[0]
        case op
        when :pop
          stack_depth -= 1
          codes << ABCPop.new(self)
        when :putnil
          inc_stack.call
          codes << ABCPushNull.new(self)
        when :putstring
          inc_stack.call
          codes << ABCPushString.new(self, @constant_pool.add_string(line[1].to_sym))
        when :getconstant
          mn = get_multiname(line[1], class_ns_set)
          codes << ABCFindPropStrict.new(self, mn)
        when :getlocal
          case line[1]
          when 1
            codes << ABCGetLocal0.new(self)
          when 2
            mbody.local_count = 2 if mbody.local_count < 2
            codes << ABCGetLocal1.new(self)
          when 3
            mbody.local_count = 3 if mbody.local_count < 3
            codes << ABCGetLocal2.new(self)
          when 4
            mbody.local_count = 4 if mbody.local_count < 4
            codes << ABCGetLocal3.new(self)
          when 5
            mbody.local_count = 5 if mbody.local_count < 5
            codes << ABCGetLocal4.new(self)
          end
        when :setlocal
          case line[1]
          when 1
            codes << ABCSetLocal0.new(self)
          when 2
            codes << ABCSetLocal1.new(self)
          when 3
            codes << ABCSetLocal2.new(self)
          when 4
            codes << ABCSetLocal3.new(self)
          when 5
            codes << ABCSetLocal4.new(self)
          end
        when :putobject
          inc_stack.call
          case line[1].class.name
          when "TrueClass"
            codes << ABCPushTrue.new(self)
          when "FalseClass"
            codes << ABCPushFalse.new(self)
          when "Fixnum"
            if line[1] < 256
              codes << ABCPushByte.new(self, line[1])
            else
              codes << ABCPushInt.new(self, @constant_pool.add_int(line[1]))
            end
          end
        when :send
          params = line[2]
          case line[1]
          when :new
            # grab the last n getconstants
            if codes.last.opcode != ABCFindPropStrict::Opcode
              # then it is a call directly on a class on the stack
            else
              # don't pop, start at -params-1
              class_name = codes.pop.property.name
              package_name = ""
              if codes.last.opcode == ABCFindPropStrict::Opcode
                first = true
                while codes.last.opcode == ABCFindPropStrict::Opcode
                  name = codes.pop.property.name.to_s
                  name = name[0].downcase + name[1..-1]
                  if first
                    package_name = name
                    first = false
                  else
                    package_name = name + "." + package_name
                  end
                end
              end
              ns_set = ns_sets[class_ns_set]
              ind = ns_set.ns_indices.dup
              ind << get_ns(ABCNamespace::PackageNamespace, package_name)
              new_set = ABCNsSet.new(ind, @constant_pool)
              new_set_index = @constant_pool.add_ns_set(new_set)
              mn = get_multiname(class_name, new_set_index)
              codes << ABCFindPropStrict.new(self, mn)
              codes << ABCConstructProp.new(self, mn, params)
              codes << ABCCoerceA.new(self)
            end
          when :get
            # :get means get a property, don't call a method, skip the get
            doing_get = true
          else
            # back up and see if there's an ABCPushNull before the params
            # if so, replace it with a findpropstrict
            # (actually, this needs to delegate to the send() method, but
            # this should work for now)
            obj = codes[-params-1]
            mn = get_multiname(line[1], class_ns_set)
            if obj.opcode == ABCPushNull::Opcode
              if doing_get
                fps = ABCGetLex.new(self, mn)
              else
                fps = ABCFindPropStrict.new(self, mn)
              end
              codes[-params-1] = fps
            else
              if doing_get
                codes << ABCGetProperty.new(self, mn)
              end
            end
            if not doing_get
              codes << ABCCallProperty.new(self, mn, params)
              codes << ABCCoerceA.new(self)
            end
            # stack pops the receiver and all params, but leaves return value
            stack_depth -= params
            doing_get = false
          end
        when :invokesuper
          codes << ABCGetLocal0.new(self)
          cs = ABCConstructSuper.new(self)
          cs.arg_count = line[1]
          codes << cs
          #stack.pop() # clear :putnil ??
        when :leave
        end
      end
    end

    # I believe every Ruby method returns a value, but the constructor
    # in ActionScript is not allowed to
    if method_name == :initialize
      codes << ABCReturnVoid.new(self)
    else
      codes << ABCReturnValue.new(self)
    end

    method_index
  end

  def split_name_package(fullname)
    fixing = fullname.gsub(/:/, ".")
    split = fixing.match(/^(?:((?:\w+\.?)*)\.)?(\w+)$/)
    name = split[2]
    package = split[1] || ""
    # downcase the first letter of each package name
    package = package.split(".").map {|s| s[0].downcase+s[1..-1]}.join(".")
    [name, package]
  end

  def protected_namespace_name(name, package)
    if package and package != ""
      package + ":" + name
    else
      name
    end
  end

  def new_class(fullname, super_fullname="")
    class_index = instances.length

    cls = ABCClass.new(self)
    classes << cls
    inst = ABCInstance.new(self)
    instances << inst

    name, package = split_name_package(fullname)
    super_name, super_package = split_name_package(super_fullname)

    # Issue Flash::Display::Sprite
    # translate to flash.display.Sprite and know what that means

    inst.name_index = get_qname(name, ABCNamespace::PackageNamespace, package)
    inst.super_name_index = get_qname(super_name, ABCNamespace::PackageNamespace, super_package)
    inst.flags = ABCInstance::ProtectedNamespace

    inst.protected_namespace_index = get_ns(ABCNamespace::ProtectedNamespace, protected_namespace_name(name, package))

    register_instance(inst)

    class_index
  end

  def get_ns(kind, name)
    name = name.to_sym if not name.is_a? Symbol
    name_index = @constant_pool.add_string(name)
    @constant_pool.add_namespace(ABCNamespace.new(kind, name_index, @constant_pool))
  end

  def get_qname(name, ns_kind, namespace)
    name = name.to_sym if not name.is_a? Symbol
    ns_index = get_ns(ns_kind, namespace)
    name_index = @constant_pool.add_string(name)
    mn_index = @constant_pool.add_multiname(ABCMultiname.new(ABCMultiname::MultinameQName, name_index, ns_index, nil, @constant_pool))
  end

  def get_multiname(name, ns_set_index)
    name = name.to_sym if not name.is_a? Symbol
    name_index = @constant_pool.add_string(name)
    mn_index = @constant_pool.add_multiname(ABCMultiname.new(ABCMultiname::Multiname, name_index, nil, ns_set_index, @constant_pool))
  end

  def set_constructor(constr)
  end
end

class ABCMethod
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
    ns = ABCMethod.new(abc_file)
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
    "#<ABCMethod:0x#{object_id.to_s(16)} @name_index=#{@name_index} @name=#{name.inspect} @return_type_index=#{@return_type_index} @return_type=#{return_type} @param_types=#{@param_types} @param_names=#{@param_names} @options=#{@options} @need_arguments=#{@need_arguments} @need_activation=#{@need_activation} @need_rest=#{@need_rest} @has_optional=#{@has_optional} @set_dxns=#{@set_dxns} @has_param_names=#{@has_param_names} @body=#{@body}>"
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
        @options << ABCMethodOptionDetail.new(io, @abc_file)
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

class ABCMethodOptionDetail
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

class ABCMetadata
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

class ABCInstance
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
    ns = ABCInstance.new(abc_file)
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
    "#<ABCInstance:0x#{object_id.to_s(16)} @name_index=#{@name_index} @name=\"#{name}\" @super_name_index=#{@super_name_index} @super_name=\"#{super_name}\" @protected_namespace_index=#{@protected_namespace_index} @flags=#{@flags} @protected_namespace=\"#{protected_namespace}\" @interface_indices=#{@interface_indices} @iinit_index=#{@iinit_index} @traits=#{@traits}>"
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
      @traits << ABCTrait.new_from_io(io, @abc_file)
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

class ABCTrait
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
    ns = ABCTrait.new(abc_file)
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

class ABCClass
  attr_accessor :cinit_index, :traits

  def self.new_from_io(io, abc_file=nil)
    ns = ABCClass.new(abc_file)
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
    "#<ABCClass:0x#{object_id.to_s(16)} @cinit_index=#{@cinit_index} @traits=#{@traits}>"
  end

  def cinit
    @abc_file.abc_methods[@cinit_index] if @abc_file and @cinit_index
  end

  def read_from_io(io)
    clear_arrays

    @cinit_index = io.read_u30
    trait_count = io.read_u30
    1.upto(trait_count) do
      @traits << ABCTrait.new_from_io(io, @abc_file)
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

class ABCScript
  attr_accessor :init_index, :traits

  def self.new_from_io(io, abc_file=nil)
    ns = ABCScript.new(abc_file)
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
      traits << ABCTrait.new_from_io(io, @abc_file)
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

class ABCMethodBody
  attr_accessor :method_index
  attr_accessor :max_stack, :local_count
  attr_accessor :init_scope_depth, :max_scope_depth
  attr_accessor :code
  attr_accessor :exceptions
  attr_accessor :traits

  def self.new_from_io(io, abc_file=nil)
    ns = ABCMethodBody.new(abc_file)
    ns.read_from_io(io)
  end

  def initialize(abc_file=nil)
    @abc_file = abc_file
    clear_arrays
  end

  def clear_arrays
    @exceptions = []
    @traits = []
    @code = ABCCode.new(@abc_file)
  end

  def method
    @abc_file.abc_methods[@method_index] if @abc_file and @method_index
  end

  def inspect
    "#<ABCMethodBody:0x#{object_id.to_s(16)} @method_index=#{@name_index} @max_stack=#{@max_stack} @local_count=#{@local_count} @init_scope_depth=#{@init_scope_depth} @max_scope_depth=#{@max_scope_depth} @exceptions=#{@exceptions} @traits=#{@traits} @code=\"#{@code.codes.length} opcodes\">"
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
    @code = ABCCode.new_from_io(StringSwfIO.new(code_data), @abc_file)

    exception_count = io.read_u30
    1.upto(exception_count) do
      @exceptions << ABCException.new(io, @abc_file)
    end

    trait_count = io.read_u30
    1.upto(trait_count) do
      @traits << ABCTrait.new_from_io(io, @abc_file)
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

class ABCException
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
    @multinames = [ABCMultiname.new(nil,nil,nil,nil,self)]
  end

  def add_arr(value, arr)
    loc = arr.index(value)
    if not loc
      loc = arr.length
      arr.push(value)
    end
    loc
  end

  def add_int(value)       add_arr(value, @ints)       end
  def add_uint(value)      add_arr(value, @uints)      end
  def add_double(value)    add_arr(value, @doubles)    end
  def add_string(value)    add_arr(value, @strings)    end
  def add_namespace(value) add_arr(value, @namespaces) end
  def add_ns_set(value)    add_arr(value, @ns_sets)    end
  def add_multiname(value) add_arr(value, @multinames) end

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
      ns = ABCNamespace.new_from_io(io, self)
      @namespaces << ns
    end

    ns_set_count = io.read_u30
    #puts("Reading #{ns_set_count} constant ns_set.")
    2.upto(ns_set_count) do
      ns = ABCNsSet.new_from_io(io, self)
      @ns_sets << ns
    end

    multiname_count = io.read_u30
    #puts("Reading #{multiname_count} constant multiname.")
    2.upto(multiname_count) do
      ns = ABCMultiname.new_from_io(io, self)
      @multinames << ns
    end

    self
  end
end

class ABCNamespace
  attr_accessor :kind, :name_index

  Namespace          = 0x08
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
    ns = ABCNamespace.new(nil,nil,constant_pool)
    ns.read_from_io(io)
  end
  def self.kind_to_s(kind)
    case kind
    when ABCNamespace::Namespace
      "Namespace"
    when ABCNamespace::PackageNamespace
      "PackageNamespace"
    when ABCNamespace::PackageInternalNs
      "PackageInternalNs"
    when ABCNamespace::ProtectedNamespace
      "ProtectedNamespace"
    when ABCNamespace::ExplicitNamespace
      "ExplicitNamespace"
    when ABCNamespace::StaticProtectedNs
      "StaticProtectedNs"
    when ABCNamespace::PrivateNs
      "PrivateNs"
    end
  end
  def initialize(kind=nil, name_index=nil, constant_pool=nil)
    @kind = kind
    @name_index = name_index
    @constant_pool = constant_pool
  end

  def inspect
    "#<ABCNamespace:0x#{object_id.to_s(16)} @kind=#{ABCNamespace.kind_to_s(@kind)} @name_index=#{@name_index} @name=#{name.inspect}>"
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
    "(#{ABCNamespace.kind_to_s(@kind)})#{name}"
  end

  def ==(o)
    @kind == o.kind and @name_index == o.name_index
  end
end

class ABCNsSet
  attr_accessor :ns_indices

  def self.new_from_io(io=nil, constant_pool=nil)
    ns = ABCNsSet.new(nil,constant_pool)
    ns.read_from_io(io)
  end

  def initialize(ns_indices=nil, constant_pool=nil)
    @ns_indices = ns_indices
    @constant_pool = constant_pool
  end

  def inspect
    "#<ABCNsSet:0x#{object_id.to_s(16)} @ns_indices=#{@ns_indices}>"
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

class ABCMultiname
  attr_accessor :kind, :ns_index, :name_index, :ns_set_index

  MultinameQName = 0x07
  MultinameQNameA = 0x0D
  MultinameRTQName = 0x0F
  MultinameRTQNameA = 0x10
  MultinameRTQNameL = 0x11
  MultinameRTQNameLA = 0x12
  Multiname = 0x09
  MultinameA = 0x0E
  MultinameL = 0x1B
  MultinameLA = 0x1C

  def self.new_from_io(io=nil, constant_pool=nil)
    m = ABCMultiname.new(nil,nil,nil,nil,constant_pool)
    m.read_from_io(io)
  end
  def self.kind_to_s(kind)
    case kind
    when nil
      "Multiname-index-0"
    when ABCMultiname::MultinameQName
      "MultinameQName"
    when ABCMultiname::MultinameQNameA
      "MultinameQNameA"
    when ABCMultiname::MultinameRTQName
      "MultinameRTQName"
    when ABCMultiname::MultinameRTQNameA
      "MultinameRTQNameA"
    when ABCMultiname::MultinameRTQNameL
      "MultinameRTQNameL"
    when ABCMultiname::MultinameRTQNameLA
      "MultinameRTQNameLA"
    when ABCMultiname::Multiname
      "Multiname"
    when ABCMultiname::MultinameA
      "MultinameA"
    when ABCMultiname::MultinameL
      "MultinameL"
    when ABCMultiname::MultinameLA
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
    "#<ABCMultiname:0x#{object_id.to_s(16)} @kind=#{ABCMultiname.kind_to_s(@kind)} @name_index=#{@name_index} @name=\"#{name}\" @ns_index=#{@ns_index} @ns=#{ns} @ns_set_index=#{@ns_set_index} @ns_set=#{ns_set}>"
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
    when Multiname, MultinameA
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
    when Multiname, MultinameA
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
      "(#{ABCMultiname.kind_to_s(@kind)})#{ns}::#{name}"
    when MultinameRTQName, MultinameRTQNameA
      "(#{ABCMultiname.kind_to_s(@kind)})stack::#{name}"
    when MultinameRTQNameL, MultinameRTQNameLA
      # no data
      "(#{ABCMultiname.kind_to_s(@kind)})stack::stack"
    when Multiname, MultinameA
      "(#{ABCMultiname.kind_to_s(@kind)})Set:#{@ns_set_index}::#{name}"
    when MultinameL, MultinameLA
      "(#{ABCMultiname.kind_to_s(@kind)})Set:#{@ns_set_index}::stack"
    end
  end
end

