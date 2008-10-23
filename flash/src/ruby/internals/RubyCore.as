package ruby.internals
{
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


  public var ID_ALLOCATOR:int;

  public var ruby_current_thread:RbThread;
  public var ruby_current_vm:RbVm;

  // Modules
  public function RubyCore()  {
  }

  include "Class_c.as"
  include "Error_c.as"
  include "Eval_c.as"
  include "Gc_c.as"
  include "Id_c.as"
  include "IO_c.as"
  include "Iseq_c.as"
  include "Object_c.as"
  include "Parse_y.as"
  include "String_c.as"
  include "Thread_c.as"

  include "Vm_c.as"

  include "Vm_eval_c.as"
  include "Vm_evalbody_c.as"
  include "Vm_insnhelper_c.as"
  include "Vm_method_c.as"
  include "Variable_c.as"

  public var rb_cFlashClass:RClass;

  public function run(docClass:DisplayObject, local_size:int, stack_max:int, block:Function):void  {
    init();
    rb_define_global_const("Document", wrap_flash_obj(docClass));
    ruby_run_node(iseqval_from_func(local_size, stack_max, block));
  }

  public function
  wrap_flash_obj(obj:Object):RData
  {
    return Data_Wrap_Struct(rb_cFlashClass, obj, null, null);
  }

  public function
  init():void
  {
    init_modules();
    ruby_init();
    init_flash_classes();
  }

  protected function
  init_modules():void
  {
    Qnil = new RNil();
    Qtrue = new RTrue();
    Qfalse = null;
    Qundef = new RUndef();
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
    ruby_init();
    ruby_run_node(n);
  }

  // inits.c:59
  public function
  rb_call_inits():void
  {

    // TODO: @skipped
    //Init_RandomSeed();
    Init_sym();
    ID_ALLOCATOR = rb_intern("allocate");
    Init_var_tables();
    Init_Object();
    Init_top_self();
    //Init_Encoding();
    //Init_Comparable();
    //Init_Enumerable();
    //Init_Precision();
    //Init_String();
    Init_Exception();
    Init_eval();
    //Init_jump();
    //Init_Numeric();
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
    Init_IO();
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
    Init_VM();
    Init_ISeq();
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
    return rb_data_object_alloc(klass, obj, mark, free);
  }

  // ruby.c:1465
  public function
  ruby_prog_init():void
  {
  }

  public function
  init_flash_classes():void
  {
    rb_cFlashClass = rb_define_class("FlashClass", rb_cObject);
    rb_define_method(rb_cFlashClass, "method_missing", fc_method_missing, -1);
  }

  public function
  fc_method_missing(argc:int, argv:Array, recv:Value):Value
  {
    var fc:Object = GetCoreDataFromValue(recv);
    var val:* = fc[rb_id2name(RSymbol(argv[0]).id)];
    if (val is Function) {
      var retval:*;
      if (argv.length > 1) {
        retval = Function(val).apply(fc, convert_array_to_as3(argv.slice(1)));
      } else {
        retval = Function(val).call(fc);
      }
      return convert_to_ruby_value(retval);
    } else {
      return wrap_flash_obj(val);
    }

    return Qnil;
  }

  public function
  convert_array_to_as3(argv:Array):Array
  {
    var new_args:Array = new Array();
    for each (var arg:* in argv) {
      new_args.push(convert_to_as3(arg));
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
    return (s << 8) | n | (ruby_running() ? 0 : Node.NOEX_BASIC);
  }

  public function NOEX_WITH_SAFE(n:uint):uint {
    return NOEX_WITH(n, rb_safe_level());
  }

  public function NEW_NODE(t:uint, a0:*, a1:*, a2:*):Node {
    return rb_node_newnode(t, a0, a1, a2);
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
      return rb_intern(RString(sym).string);
    } else {
      return -1;
    }
  }

  // ruby.h:1048
  public function
  rb_class_of(obj:Value):RClass
  {
    // TODO: @skipped
    // Test for immediate objects and special values
    if (obj == Qnil)   return rb_cNilClass;
    if (obj == Qtrue)  return rb_cTrueClass;
    if (obj == Qfalse) return rb_cFalseClass;
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
  TOPN(sp:Array, n:int):Value
  {
    return sp[sp.length-n-1];
  }


  public function
  iseqval_from_func(local_size:int, stack_max:int, func:Function):Value
  {
    // Look at ruby.c:961 process_options() and vm.c Init_VM

    // Pass in null for the node first
    var iseqval:Value = rb_iseq_new(null, rb_str_new2("<main>"), rb_str_new2("filename.rb"), Qfalse, RbVm.ISEQ_TYPE_TOP);

    // Get the iseq out and assign the function pointer
    var iseq:RbISeq = GetISeqPtr(iseqval);
    iseq.arg_size = 0;
    iseq.local_size = local_size;
    iseq.stack_max = stack_max;
    iseq.iseq_fn = func;

    return iseqval;
  }

  public function
  class_iseq_from_func(name:String, arg_size:int, local_size:int, stack_max:int, func:Function):RbISeq
  {
    var iseqval:Value = rb_iseq_new(null, rb_str_new2("<class:"+name+">"), rb_str_new2("filename.rb"), Qfalse, RbVm.ISEQ_TYPE_CLASS);
    var class_iseq:RbISeq = GetISeqPtr(iseqval);
    class_iseq.arg_size = arg_size;
    class_iseq.local_size = local_size;
    class_iseq.stack_max = stack_max;
    class_iseq.iseq_fn = func;

    return class_iseq;
  }

  public function
  method_iseq_from_func(name:String, arg_size:int, local_size:int, stack_max:int, func:Function):RbISeq
  {
    var iseqval:Value = rb_iseq_new(null, rb_str_new2(name), rb_str_new2("filename.rb"), Qfalse, RbVm.ISEQ_TYPE_METHOD);
    var class_iseq:RbISeq = GetISeqPtr(iseqval);
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

}
}

