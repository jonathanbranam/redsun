package ruby.internals
{
import com.adobe.serialization.json.JSONDecoder;

import flash.display.DisplayObject;

/**
 * Class for core ruby methods.
 */
public class RubyCore
{
  public var Qnil:Value;
  public var Qundef:Value;
  public var Qfalse:Value;
  public var Qtrue:Value;
  public var Qpause:Value;


  public var ID_ALLOCATOR:int;

  public var ruby_current_thread:RbThread;
  public var ruby_current_vm:RbVm;
  public var ruby_initialized:Boolean = false;

  // Modules

  public var rc:RubyCore;
  public var class_c:Class_c;
  public var error_c:Error_c;
  public var eval_c:Eval_c;
  public var gc_c:Gc_c;
  public var io_c:IO_c;
  public var id_c:Id_c;
  public var iseq_c:Iseq_c;
  public var numeric_c:Numeric_c;
  public var object_c:Object_c;
  public var parse_y:Parse_y;
  public var proc_c:Proc_c;
  public var string_c:String_c;
  public var thread_c:Thread_c;
  public var variable_c:Variable_c;
  public var vm_c:Vm_c;
  public var vm_eval_c:Vm_eval_c;
  public var vm_evalbody_c:Vm_evalbody_c;
  public var vm_insnhelper_c:Vm_insnhelper_c;
  public var vm_method_c:Vm_method_c;

  public function RubyCore()  {
    class_c = new Class_c();
    class_c.rc = this;
    error_c = new Error_c();
    error_c.rc = this;
    eval_c = new Eval_c();
    eval_c.rc = this;
    gc_c = new Gc_c();
    gc_c.rc = this;
    io_c = new IO_c();
    io_c.rc = this;
    id_c = new Id_c();
    id_c.rc = this;

    iseq_c = new Iseq_c();
    iseq_c.rc = this;
    numeric_c = new Numeric_c();
    numeric_c.rc = this;
    object_c = new Object_c();
    object_c.rc = this;

    parse_y = new Parse_y();
    parse_y.rc = this;
    proc_c = new Proc_c();
    proc_c.rc = this;
    string_c = new String_c();
    string_c.rc = this;

    thread_c = new Thread_c();
    thread_c.rc = this;
    variable_c = new Variable_c();
    variable_c.rc = this;

    vm_c = new Vm_c();
    vm_c.rc = this;
    vm_eval_c = new Vm_eval_c();
    vm_eval_c.rc = this;
    vm_evalbody_c = new Vm_evalbody_c();
    vm_evalbody_c.rc = this;
    vm_insnhelper_c = new Vm_insnhelper_c();
    vm_insnhelper_c.rc = this;
    vm_method_c = new Vm_method_c();
    vm_method_c.rc = this;

    rc = this;
  }

  //include "Class_c.as"
  //include "Error_c.as"
  //include "Eval_c.as"
  //include "Gc_c.as"
  //include "Id_c.as"
  //include "IO_c.as"
  //include "Iseq_c.as"
  //include "Numeric_c.as"
  //include "Object_c.as"
  //include "Parse_y.as"
  //include "Proc_c.as"
  //include "String_c.as"
  //include "Thread_c.as"

  //include "Variable_c.as"
  //include "Vm_c.as"

  //include "Vm_eval_c.as"
  //include "Vm_evalbody_c.as"
  //include "Vm_insnhelper_c.as"
  //include "Vm_method_c.as"

  public var rb_cFlashClass:RClass;

  public function run_func(docClass:DisplayObject, local_size:int, stack_max:int, block:Function):void  {
    init();
    rc.variable_c.rb_define_global_const("Document", wrap_flash_obj(docClass));
    rc.eval_c.ruby_run_node(iseqval_from_func(local_size, stack_max, block));
  }

  public function run(bytecode:String, doc_class:DisplayObject=null):void  {
    var decoder:JSONDecoder = new JSONDecoder( bytecode, this )
    run_array(decoder.getValue(), doc_class);
  }

  public function run_array(iseq_array:Array, doc_class:DisplayObject=null):void {
    init();
    run_iseqval(iseqval_from_array(iseq_array), doc_class);
  }

  public function run_iseqval(iseqval:Value, doc_class:DisplayObject=null):void {
    init();
    if (doc_class) {
      rc.variable_c.rb_define_global_const("Document", wrap_flash_obj(doc_class));
    }
    rc.eval_c.ruby_run_node(iseqval);
  }

  public function
  wrap_flash_obj(obj:Object):RData
  {
    return Data_Wrap_Struct(rb_cFlashClass, obj, null, null);
  }

  public function
  init():void
  {
    if (!ruby_initialized) {
      ruby_initialized = true;
      init_modules();
      rc.eval_c.ruby_init();
      init_flash_classes();
    }
  }

  protected function
  init_modules():void
  {
    Qnil = new RNil();
    Qtrue = new RTrue();
    Qfalse = null;
    Qundef = new RUndef();
    Qpause = new Value(); // new RPause(); ???
  }

  public function GET_THREAD():RbThread {
    return ruby_current_thread;
  }

  // main.c:21
  public function
  main(n:Value):void
  {
    // TODO: @skipped
    //ruby_set_debug_option(getenv("RUBY_DEBUG"));
    //ruby_sysinit(&argc, &argv);
    //RUBY_INIT_STACK;
    rc.eval_c.ruby_init();
    rc.eval_c.ruby_run_node(n);
  }

  // inits.c:59
  public function
  rb_call_inits():void
  {

    // TODO: @skipped
    //Init_RandomSeed();
    rc.parse_y.Init_sym();
    ID_ALLOCATOR = rc.parse_y.rb_intern("allocate");
    rc.variable_c.Init_var_tables();
    rc.object_c.Init_Object();
    rc.vm_c.Init_top_self();
    //Init_Encoding();
    //Init_Comparable();
    //Init_Enumerable();
    //Init_Precision();
    //Init_String();
    rc.error_c.Init_Exception();
    rc.eval_c.Init_eval();
    //Init_jump();
    rc.numeric_c.Init_Numeric();
    //Init_Bignum();
    //Init_syserr();
    //Init_Array();
    //Init_Hash();
    //Init_Struct();
    //Init_Regexp();
    //Init_pack();
    //Init_transcode();
    //Init_marshal();
    //Init_Range();
    rc.io_c.Init_IO();
    //Init_Dir();
    //Init_Time();
    //Init_Random();
    //Init_signal();
    //Init_process();
    //Init_load();
    //Init_Proc();
    //Init_Binding();
    //Init_Math();
    //Init_GC();
    //Init_Enumerator();
    rc.vm_c.Init_VM();
    rc.iseq_c.Init_ISeq();
    //Init_Thread();
    //Init_Cont();
    //Init_Rational();
    //Init_Complex();
    //Init_version();
  }

  public function
  RSTRING_PTR(val:Value):String
  {
    if (val.get_type() == Value.T_STRING) {
      return RString(val).string;
    } else {
      return null;
    }
  }



  public function
  GET_VM():RbVm
  {
    return ruby_current_vm;
  }

  // ruby.h:672
  public function
  Data_Wrap_Struct(klass:RClass, obj:*, mark:Function, free:Function):RData
  {
    return rc.gc_c.rb_data_object_alloc(klass, obj, mark, free);
  }

  // ruby.c:1465
  public function
  ruby_prog_init():void
  {
  }

  public function
  init_flash_classes():void
  {
    rb_cFlashClass = class_c.rb_define_class("FlashClass", rc.object_c.rb_cObject);
    class_c.rb_define_method(rb_cFlashClass, "method_missing", fc_method_missing, -1);
  }

  public function
  fc_method_missing(argc:int, argv:StackPointer, recv:Value):Value
  {
    var fc:Object = rc.vm_c.GetCoreDataFromValue(recv);
    var val:* = fc[rc.parse_y.rb_id2name(RSymbol(argv.get_at(0)).id)];
    if (val is Function) {
      var retval:*;
      //var func:Function = Function(val);
      if (argc > 1) {
        var as3_args:Array = convert_array_to_as3(argc-1, argv.clone_down_stack(1));
        retval = val.apply(fc, as3_args);
      } else {
        retval = val.call(fc);
      }
      return convert_to_ruby_value(retval);
    } else {
      return wrap_flash_obj(val);
    }

    return Qnil;
  }

  public function
  convert_array_to_as3(argc:int, argv:StackPointer):Array
  {
    var new_args:Array = new Array();
    for (var i:int = 0; i < argc; i++) {
      new_args.push(convert_to_as3(argv.get_at(i)));
    }
    return new_args;
  }

  public function
  convert_to_as3(val:*):*
  {
    if (val == Qundef) {
      return undefined;
    } else if (val == Qnil) {
      return null;
    } else if (val == Qtrue) {
      return true;
    } else if (val == Qfalse) {
      return false;
    } else if (val is RInt) {
      return RInt(val).value;
    } else if (val is Value) {
      var v:Value = Value(val);
      var type:uint = v.get_type();
      switch (type) {
        case Value.T_STRING:
          return RSTRING_PTR(v);
        default:
          return v;
      }
    }
  }

  public function
  convert_array_to_ruby_value(argv:Array):Array
  {
    var new_args:Array = new Array();
    for each (var arg:* in argv) {
      new_args.push(convert_to_ruby_value(arg));
    }
    return new_args;
  }

  public function
  convert_to_ruby_value(val:*):*
  {
    if (val == undefined || val == null) {
      return Qnil;
    } else if (val is RProxy) {
      return val.ruby_value;
    } else if (val == true) {
      return Qtrue;
    } else if (val == false) {
      return Qfalse;
    }
  }

  public function
  ID2SYM(x:int):Value
  {
    var sym:RSymbol = new RSymbol();
    sym.id = x;
    return sym;
  }

  public function NOEX_SAFE(n:uint):uint {
    return (n >> 8) & 0x0F;
  }

  public function NOEX_WITH(n:uint, s:uint):uint {
    return (s << 8) | n | (vm_method_c.ruby_running() ? 0 : Node.NOEX_BASIC);
  }

  public function NOEX_WITH_SAFE(n:uint):uint {
    return NOEX_WITH(n, rb_safe_level());
  }

  public function NEW_NODE(t:uint, a0:*, a1:*, a2:*):Node {
    return rc.gc_c.rb_node_newnode(t, a0, a1, a2);
  }

  public function NEW_BLOCK(a:*):Node {
    return NEW_NODE(Node.NODE_BLOCK, a, null, null);
  }

  public function NEW_CFUNC(f:Function, c:int):Node {
    return NEW_NODE(Node.NODE_CFUNC, f, c, null);
  }

  public function NEW_METHOD(n:Value,x:Value,v:uint):Node {
    return NEW_NODE(Node.NODE_METHOD, x, n, v);
  }

  public function NEW_FBODY(n:Value,i:Value):Node {
    return NEW_NODE(Node.NODE_FBODY, i, n, null);
  }

  // eval_safe.c:19
  public function
  rb_safe_level():int
  {
    return GET_THREAD().safe_level;
  }

  public function RTEST(v:Value):Boolean {
    // TODO: @skipped
    //  (((VALUE)(v) & ~Qnil) != 0)
    return v != null && v != Qnil;
  }

  public function NIL_P(v:Value):Boolean { return v == Qnil; }

  public function SYMBOL_P(v:Value):Boolean { return v is RSymbol; }

  public function SYM2ID(sym:Value):int {
    if (sym.get_type() == Value.T_SYMBOL) {
      return RSymbol(sym).id;
    }
    if (sym.get_type() == Value.T_STRING) {
      return rc.parse_y.rb_intern(RString(sym).string);
    } else {
      return -1;
    }
  }

  public function
  FIXNUM_P(v:Value):Boolean
  {
    return v.get_type() == Value.T_FIXNUM;
  }

  // ruby.h:1048
  public function
  rb_class_of(obj:Value):RClass
  {
    // TODO: @skipped
    // Test for immediate objects and special values

    // false test first b/c Qfalse == null
    if (obj == Qfalse) return rc.object_c.rb_cFalseClass;

    if (FIXNUM_P(obj)) {
      return rc.numeric_c.rb_cFixnum;
    }

    if (obj == Qnil)   return rc.object_c.rb_cNilClass;
    if (obj == Qtrue)  return rc.object_c.rb_cTrueClass;
    return RBasic(obj).klass;
  }

  public function
  CLASS_OF(v:Value):RClass
  {
    return rb_class_of(v);
  }

  public function
  RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp:RbControlFrame):RbBlock
  {
    return cfp;
  }

  public function
  TOPN(sp:StackPointer, n:int):Value
  {
    return sp.topn(n);
    //return sp[sp.length-n-1];
  }


  public function
  iseqval_from_func(local_size:int, stack_max:int, func:Function):Value
  {
    // Look at ruby.c:961 process_options() and vm.c Init_VM

    // Pass in null for the node first
    var iseqval:Value = rc.iseq_c.rb_iseq_new(null, rc.string_c.rb_str_new2("<main>"),
                                              rc.string_c.rb_str_new2("filename.rb"), Qfalse, RbVm.ISEQ_TYPE_TOP);

    // Get the iseq out and assign the function pointer
    var iseq:RbISeq = rc.iseq_c.GetISeqPtr(iseqval);
    iseq.arg_size = 0;
    iseq.local_size = local_size;
    iseq.stack_max = stack_max;
    iseq.iseq_fn = func;

    return iseqval;
  }

  public function
  yarv_stack_obj(iseq_array:Array):Object
  {
    return iseq_array[4];
  }

  public function
  yarv_arg_simple(iseq_array:Array):int
  {
    if (iseq_array[9] is Array) {
      return iseq_array[9][0];
    } else {
      return iseq_array[9];
    }
  }

  public function
  yarv_arg_array(iseq_array:Array):Array
  {
    return iseq_array[9] as Array;
  }

  public function
  get_index_or_default(array:Array, index:int, default_value:int):int
  {
    if (array) {
      return array[index];
    } else {
      return default_value;
    }
  }

  public function
  yarv_arg_size(iseq_array:Array):int
  {
    return yarv_stack_obj(iseq_array).arg_size;
  }

  public function
  yarv_local_size(iseq_array:Array):int
  {
    return yarv_stack_obj(iseq_array).local_size;
  }

  public function
  yarv_stack_max(iseq_array:Array):int
  {
    return yarv_stack_obj(iseq_array).stack_max;
  }

  public function
  yarv_iseq(iseq_array:Array):Array
  {
    return iseq_array[11];
  }

  public function
  iseqval_from_array(iseq_array:Array, parent:Value=null):Value
  {
    // Look at ruby.c:961 process_options() and vm.c Init_VM

    var type:int;
    var type_str:String = iseq_array[7];
    if (type_str == "top") {
      type = RbVm.ISEQ_TYPE_TOP;
    } else if (type_str == "block") {
      type = RbVm.ISEQ_TYPE_BLOCK;
    } else if (type_str == "method") {
      type = RbVm.ISEQ_TYPE_METHOD;
    } else if (type_str == "class") {
      type = RbVm.ISEQ_TYPE_CLASS;
    } else if (type_str == "ensure") {
      type = RbVm.ISEQ_TYPE_ENSURE;
    } else if (type_str == "rescue") {
      type = RbVm.ISEQ_TYPE_RESCUE;
    } else {
      rc.error_c.rb_bug("unknown iseq type: " + type_str);
    }

    parent = parent ? parent : Qfalse;

    // Pass in null for the node first
    var iseqval:Value = rc.iseq_c.rb_iseq_new(null, rc.string_c.rb_str_new2("<main>"),
                                              rc.string_c.rb_str_new2("filename.rb"), parent, type);

    // Get the iseq out and assign the function pointer
    var iseq:RbISeq = rc.iseq_c.GetISeqPtr(iseqval);
    iseq.arg_size = yarv_arg_size(iseq_array);
    iseq.local_size = yarv_local_size(iseq_array);
    iseq.stack_max = yarv_stack_max(iseq_array);

    var arg_array:Array = yarv_arg_array(iseq_array);
    iseq.arg_rest = yarv_arg_rest(arg_array);
    iseq.arg_block = yarv_arg_block(arg_array);
    iseq.arg_post_len = yarv_arg_post_len(arg_array);
    iseq.arg_post_start = yarv_arg_post_start(arg_array);
    iseq.arg_opt_table = yarv_arg_opt_table(arg_array);
    iseq.arg_opts = yarv_arg_opts(iseq);

    iseq.argc = yarv_arg_simple(iseq_array);
    if (iseq.argc == iseq.arg_size) {
      iseq.arg_simple = 1;
    } else {
      iseq.arg_simple = 0;
    }
    if (iseq.arg_opts != 0 || iseq.arg_post_len != 0 ||
        iseq.arg_rest != -1 || iseq.arg_block != -1) {
      if (iseq.arg_simple != 0) {
        trace("WHAT!?! HOW DID ARG_SIMPLE GET SET TO 1??");
      }
      iseq.arg_simple = 0;
    }

    iseq.iseq = yarv_iseq(iseq_array);

    return iseqval;
  }


  public function yarv_arg_rest(a:Array):int       { return get_index_or_default(a, 4, -1); }
  public function yarv_arg_block(a:Array):int      { return get_index_or_default(a, 5, -1); }
  public function yarv_arg_post_len(a:Array):int   { return get_index_or_default(a, 2, 0); }
  public function yarv_arg_post_start(a:Array):int { return get_index_or_default(a, 3, 0); }

  public function yarv_arg_opts(iseq:RbISeq):int
  {
    if (iseq.arg_opt_table && iseq.arg_opt_table.length > 1) {
      return iseq.arg_opt_table.length-1;
    } else {
      return 0;
    }
  }

  public function
  yarv_arg_opt_table(a:Array):Array
  {
    if (!a) {
      return null;
    } else {
      return a[1] as Array;
    }
  }

  public function
  class_iseq_from_func(name:String, arg_size:int, local_size:int, stack_max:int, func:Function):RbISeq
  {
    var iseqval:Value = rc.iseq_c.rb_iseq_new(null, rc.string_c.rb_str_new2("<class:"+name+">"),
                                              rc.string_c.rb_str_new2("filename.rb"),
                                              Qfalse, RbVm.ISEQ_TYPE_CLASS);
    var class_iseq:RbISeq = rc.iseq_c.GetISeqPtr(iseqval);
    class_iseq.arg_size = arg_size;
    class_iseq.local_size = local_size;
    class_iseq.stack_max = stack_max;
    class_iseq.iseq_fn = func;

    return class_iseq;
  }

  public function
  method_iseq_from_func(name:String, arg_size:int, local_size:int, stack_max:int, func:Function):RbISeq
  {
    var iseqval:Value = rc.iseq_c.rb_iseq_new(null, rc.string_c.rb_str_new2(name),
                                              rc.string_c.rb_str_new2("filename.rb"),
                                              Qfalse, RbVm.ISEQ_TYPE_METHOD);
    var class_iseq:RbISeq = rc.iseq_c.GetISeqPtr(iseqval);
    class_iseq.arg_size = arg_size;
    class_iseq.local_size = local_size;
    class_iseq.stack_max = stack_max;
    class_iseq.iseq_fn = func;

    return class_iseq;
  }

  public function
  COPY_CREF(c1:Node, c2:Node):void
  {
    c1.nd_clss = c2.nd_clss;
    c1.nd_visi = c2.nd_visi;
    c1.nd_next = c2.nd_next;
  }

  public function
  Check_Type(v:Value, t:int):void
  {
    rc.error_c.rb_check_type(v, t);
  }

  // ruby.h
  public function
  TYPE(x:Value):int
  {
    return rb_type(x);
  }

  // ruby.h:1063
  public function
  rb_type(obj:Value):int
  {
    // Must check false first since it is a null pointer
    if (obj == Qfalse) return Value.T_FALSE;
    if (obj == Qtrue) return Value.T_TRUE;
    if (SYMBOL_P(obj)) return Value.T_SYMBOL;
    if (obj == Qundef) return Value.T_UNDEF;

    if (!RTEST(obj)) {
      if (obj == Qnil) return Value.T_NIL;
      // false already handled
      //if (obj == Qfalse) return Value.T_FALSE;
    }
    return obj.BUILTIN_TYPE();
  }

  // ruby.h:262
  public function
  IMMEDIATE_P(x:Value):Boolean
  {
    if (x == Qfalse) return true;
    if (FIXNUM_P(x)) return true;
    if (x == Qtrue) return true;
    if (SYMBOL_P(x)) return true;
    if (x == Qundef) return true;

    return false;
  }

  // ruby.h:792
  public function
  SPECIAL_CONST_P(x:Value):Boolean
  {
    return IMMEDIATE_P(x) || !RTEST(x);
  }

  // ruby.h:1079
  public function
  rb_special_const_p(obj:Value):Boolean
  {
    if (SPECIAL_CONST_P(obj)) return true;
    return false;
  }

  // ruby.h:872
  public function
  CONST_ID(str:String):int
  {
    return rc.parse_y.rb_intern2(str);
  }

}
}

