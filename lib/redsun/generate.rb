#!/usr/bin/ruby

require 'zlib'
require 'redsun/stringio'
require 'redsun/tags'

module RedSun

  class Swf

    def create_stub_swf(doc_class_name="EmptySwf", ruby_code=nil)
      set_defaults
      @compressed = true
      @tags = []

      file_attributes = Tags::FileAttributes.new
      file_attributes.actionscript3 = true
      file_attributes.use_network = true
      file_attributes.has_metadata = false
      @tags << file_attributes

      script_limits = Tags::ScriptLimits.new
      script_limits.max_recursion_depth = 1000
      script_limits.script_timeout_secs = 60
      @tags << script_limits

      bg_color = Tags::SetBackgroundColor.new
      bg_color.background_color = 0x869ca7
      @tags << bg_color

      frame_label = Tags::FrameLabel.new
      frame_label.name = doc_class_name
      @tags << frame_label

      abc = Tags::DoABC.new
      abc.flags = 1

      abc.name = "frame1"
      abc.abc_file = ABC::ABCFile.new

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

      symbol_class = Tags::SymbolClass.new
      symbol_class.symbols=[{:tag=>0, :name=>doc_class_name}]
      @tags << symbol_class

      show_frame = Tags::ShowFrame.new
      @tags << show_frame

      end_tag = Tags::End.new
      @tags << end_tag

    end

  end

  module ABC

    class ABCFile


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
        scr = Script.new(self)
        script_index = scripts.length
        scripts << scr

        method_index, mbody_index = create_method()
        method = @abc_methods[method_index]
        mbody = @method_bodies[mbody_index]

        method.return_type_index = 0
        method.name_index = @constant_pool.add_string("".to_sym)

        scr.init_index = method_index

        trait = Trait.new(self)
        scr.traits << trait

        trait.name_index = inst.name_index
        trait.type = Trait::ClassId
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

        ns_indices << get_ns(Namespace::PrivateNs, ns_from_class_multiname(inst.name))
        ns_indices << get_ns(Namespace::PrivateNs, "file.as")

        ns_indices << get_ns(Namespace::PackageNamespace, inst.name.ns.name)
        ns_indices << get_ns(Namespace::PackageInternalNs, inst.name.ns.name)
        ns_indices << get_ns(Namespace::ProtectedNamespace, ns_from_class_multiname(inst.name))
        ns_indices << get_ns(Namespace::StaticProtectedNs, ns_from_class_multiname(inst.name))

        hierarchy = get_hierarchy(inst.name).reverse
        hierarchy.each do |clz_sym|
          match = clz_sym.to_s.match(/^([\w.]+:)?(\w+)$/)
          package, name = match[1] || "", match[2]
          ns_indices << get_ns(Namespace::StaticProtectedNs, package+name)
        end


        @constant_pool.add_ns_set(NsSet.new(ns_indices, @constant_pool))
      end

      def create_class_init_method_body(inst, class_index, mbody)
        mbody.max_stack = 2
        mbody.local_count = 1
        mbody.init_scope_depth = 1
        # number of parent classes
        mbody.max_scope_depth = 8

        codes = mbody.code.codes

        codes << GetLocal0.new(self)
        codes << PushScope.new(self)

        # let caller insert opcode to get the target object
        yield codes

        hierarchy = get_hierarchy(inst.name)
        hierarchy.each do |clz_sym|
          gl = GetLex.new(self)
          match = clz_sym.to_s.match(/^(?:([\w.]+):)?(\w+)$/)
          package, name = match[1] || "", match[2]
          gl.index = get_qname(name, Namespace::PackageNamespace, package)
          codes << gl
          codes << PushScope.new(self)
        end

        gl = GetLex.new(self)
        clz_sym = hierarchy.last
        match = clz_sym.to_s.match(/^(?:([\w.]+):)?(\w+)$/)
        package, name = match[1] || "", match[2]
        gl.index = get_qname(name, Namespace::PackageNamespace, package)
        codes << gl

        nc = NewClass.new(self)
        nc.index = class_index
        codes << nc

        hierarchy.each do |clz|
          codes << PopScope.new(self)
        end

        ip = InitProperty.new(self)
        ip.index = inst.name_index
        codes << ip

        codes << ReturnVoid.new(self)
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
          op = GetScopeObject.new(self)
          op.index = 0
          codes << op
        end
      end

      def create_class_init_script(inst, class_index)
        script_index = shared_class_script_init(inst, class_index)
        scr = scripts[script_index]

        create_class_init_method_body(inst, class_index, scr.init.body) do |codes|
          op = FindPropStrict.new(self)
          # set multiname ns_set and classname
          codes << op
        end
      end

      def create_method()
        method = Method.new(self)
        method_index = @abc_methods.length
        @abc_methods << method
        mbody = MethodBody.new(self)
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
        codes << GetLocal0.new(self)
        codes << PushScope.new(self)

        prot_mn = get_multiname(:prototype, class_ns_set) if not methods.empty?
        # JPB
        methods.each do |index|
          name = @abc_methods[index].name.to_s
          name.match(/^(?:\w+\/)?(\w+)$/)
          mn = get_multiname($1, class_ns_set)
          codes << GetLex.new(self, prot_mn)
          codes << NewFunction.new(self, index)
          codes << SetProperty.new(self, mn)
        end


        codes << ReturnVoid.new(self)

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
        codes << GetLocal0.new(self)
        codes << PushScope.new(self)

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
              codes << Pop.new(self)
            when :putnil
              inc_stack.call
              codes << PushNull.new(self)
            when :putstring
              inc_stack.call
              codes << PushString.new(self, @constant_pool.add_string(line[1].to_sym))
            when :getconstant
              mn = get_multiname(line[1], class_ns_set)
              codes << FindPropStrict.new(self, mn)
            when :getlocal
              case line[1]
              when 1
                codes << GetLocal0.new(self)
              when 2
                mbody.local_count = 2 if mbody.local_count < 2
                codes << GetLocal1.new(self)
              when 3
                mbody.local_count = 3 if mbody.local_count < 3
                codes << GetLocal2.new(self)
              when 4
                mbody.local_count = 4 if mbody.local_count < 4
                codes << GetLocal3.new(self)
              when 5
                mbody.local_count = 5 if mbody.local_count < 5
                codes << GetLocal4.new(self)
              end
            when :setlocal
              case line[1]
              when 1
                codes << SetLocal0.new(self)
              when 2
                codes << SetLocal1.new(self)
              when 3
                codes << SetLocal2.new(self)
              when 4
                codes << SetLocal3.new(self)
              when 5
                codes << SetLocal4.new(self)
              end
            when :putobject
              inc_stack.call
              case line[1].class.name
              when "TrueClass"
                codes << PushTrue.new(self)
              when "FalseClass"
                codes << PushFalse.new(self)
              when "Fixnum"
                if line[1] < 256
                  codes << PushByte.new(self, line[1])
                else
                  codes << PushInt.new(self, @constant_pool.add_int(line[1]))
                end
              end
            when :send
              params = line[2]
              case line[1]
              when :new
                # grab the last n getconstants
                if codes.last.opcode != FindPropStrict::Opcode
                  # then it is a call directly on a class on the stack
                else
                  # don't pop, start at -params-1
                  class_name = codes.pop.property.name
                  package_name = ""
                  if codes.last.opcode == FindPropStrict::Opcode
                    first = true
                    while codes.last.opcode == FindPropStrict::Opcode
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
                  ind << get_ns(Namespace::PackageNamespace, package_name)
                  new_set = NsSet.new(ind, @constant_pool)
                  new_set_index = @constant_pool.add_ns_set(new_set)
                  mn = get_multiname(class_name, new_set_index)
                  codes << FindPropStrict.new(self, mn)
                  codes << ConstructProp.new(self, mn, params)
                  codes << CoerceA.new(self)
                end
              when :get
                # :get means get a property, don't call a method, skip the get
                doing_get = true
              else
                # back up and see if there's an PushNull before the params
                # if so, replace it with a findpropstrict
                # (actually, this needs to delegate to the send() method, but
                # this should work for now)
                obj = codes[-params-1]
                mn = get_multiname(line[1], class_ns_set)
                if obj.opcode == PushNull::Opcode
                  if doing_get
                    fps = GetLex.new(self, mn)
                  else
                    fps = FindPropStrict.new(self, mn)
                  end
                  codes[-params-1] = fps
                else
                  if doing_get
                    codes << GetProperty.new(self, mn)
                  end
                end
                if not doing_get
                  codes << CallProperty.new(self, mn, params)
                  codes << CoerceA.new(self)
                end
                # stack pops the receiver and all params, but leaves return value
                stack_depth -= params
                doing_get = false
              end
            when :invokesuper
              codes << GetLocal0.new(self)
              cs = ConstructSuper.new(self)
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
          codes << ReturnVoid.new(self)
        else
          codes << ReturnValue.new(self)
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

        cls = Class.new(self)
        classes << cls
        inst = Instance.new(self)
        instances << inst

        name, package = split_name_package(fullname)
        super_name, super_package = split_name_package(super_fullname)

        # Issue Flash::Display::Sprite
        # translate to flash.display.Sprite and know what that means

        inst.name_index = get_qname(name, Namespace::PackageNamespace, package)
        inst.super_name_index = get_qname(super_name, Namespace::PackageNamespace, super_package)
        inst.flags = Instance::ProtectedNamespace

        inst.protected_namespace_index = get_ns(Namespace::ProtectedNamespace, protected_namespace_name(name, package))

        register_instance(inst)

        class_index
      end

      def get_ns(kind, name)
        name = name.to_sym if not name.is_a? Symbol
        name_index = @constant_pool.add_string(name)
        @constant_pool.add_namespace(Namespace.new(kind, name_index, @constant_pool))
      end

      def get_qname(name, ns_kind, namespace)
        name = name.to_sym if not name.is_a? Symbol
        ns_index = get_ns(ns_kind, namespace)
        name_index = @constant_pool.add_string(name)
        mn_index = @constant_pool.add_multiname(Multiname.new(Multiname::MultinameQName, name_index, ns_index, nil, @constant_pool))
      end

      def get_multiname(name, ns_set_index)
        name = name.to_sym if not name.is_a? Symbol
        name_index = @constant_pool.add_string(name)
        mn_index = @constant_pool.add_multiname(Multiname.new(Multiname::MultinameC, name_index, nil, ns_set_index, @constant_pool))
      end

      def set_constructor(constr)
      end


    end

    class ConstantPool


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


    end

  end

end
