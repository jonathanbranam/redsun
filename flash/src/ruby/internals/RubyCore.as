package ruby.internals
{
import com.adobe.serialization.json.JSONDecoder;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Timer;

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
  public var array_c:Array_c;
  public var class_c:Class_c;
  public var enum_c:Enum_c;
  public var error_c:Error_c;
  public var eval_c:Eval_c;
  public var gc_c:Gc_c;
  public var hash_c:Hash_c;
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

  public function RubyCore()
  {
    array_c = new Array_c();
    array_c.rc = this;
    class_c = new Class_c();
    class_c.rc = this;
    enum_c = new Enum_c();
    enum_c.rc = this;
    error_c = new Error_c();
    error_c.rc = this;
    eval_c = new Eval_c();
    eval_c.rc = this;
    gc_c = new Gc_c();
    gc_c.rc = this;
    hash_c = new Hash_c();
    hash_c.rc = this;
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

  }

  public var rb_cFlashObject:RClass;
  public var rb_cFlashClass:RClass;

  public function
  run_func(doc_class:DisplayObject, local_size:int, stack_max:int, block:Function):void
  {
    init();
    variable_c.rb_define_global_const("TopSprite", wrap_flash_obj(doc_class));
    eval_c.ruby_run_node(iseqval_from_func(local_size, stack_max, block));
  }

  public function
  run(bytecode:String, doc_class:DisplayObject=null):void
  {
    var decoder:JSONDecoder = new JSONDecoder( bytecode, this )
    run_array(decoder.getValue(), doc_class);
  }

  public function
  run_array(iseq_array:Array, doc_class:DisplayObject=null):void
  {
    init();
    run_iseqval(iseqval_from_array(iseq_array), doc_class);
  }

  public function
  run_iseqval(iseqval:Value, doc_class:DisplayObject=null):void
  {
    init();
    if (doc_class) {
      variable_c.rb_define_global_const("TopSprite", wrap_flash_obj(doc_class));
    }
    eval_c.ruby_run_node(iseqval);
  }

  public function
  wrap_flash_obj(obj:Object):RData
  {
    return Data_Wrap_Struct(rb_cFlashObject, obj, null, null);
  }

  public function
  wrap_flash_class(klass:Class):RData
  {
    return Data_Wrap_Struct(rb_cFlashClass, klass, null, null);
  }

  public function
  init():void
  {
    if (!ruby_initialized) {
      ruby_initialized = true;
      init_modules();
      eval_c.ruby_init();
      init_flash_classes();
      init_global_funcs();
    }
  }

  protected function
  init_global_funcs():void
  {
    class_c.rb_define_global_function("wait", wait_func, 1);
    class_c.rb_define_singleton_method(vm_c.rb_vm_top_self(), "on", on_top_func, 1);
  }

  protected function
  on_top_func(recv:Value, event_name:Value):Value
  {
    var top:EventDispatcher;
    var docval:Value = variable_c.rb_const_get(object_c.rb_cObject, parse_y.rb_intern("TopSprite"));
    top = RData(docval).data;
    var str:RString = string_c.rb_obj_as_string(event_name);

    var rc:RubyCore = this;
    var th:RbThread = rc.GET_THREAD();
    var block:RbBlock = vm_insnhelper_c.GET_BLOCK_PTR(GET_THREAD().cfp);

    var blockval:Value = rc.Qnil;
    // make Proc object
    if (block.proc == null) {
      var proc:RbProc;

      blockval = rc.vm_c.vm_make_proc(th, th.cfp, block, rc.proc_c.rb_cProc);

      proc = rc.vm_c.GetProcPtr(blockval);
      //block.v = proc.block;
    }
    else {
      blockval = block.proc;
    }
    //orig_argv.set_at(iseq.arg_block, blockval); // Proc or nil

    top.addEventListener(str.string, function (e:Event):void {
      rc.bare_block_call(blockval, rc.wrap_flash_obj(e));
    });

    return Qnil;
  }

  protected function
  fo_on(recv:Value, event_name:Value):Value
  {
    var dispatcher:EventDispatcher;
    var flash_obj:Object = vm_c.GetCoreDataFromValue(recv);
    dispatcher = EventDispatcher(flash_obj);
    var str:RString = string_c.rb_obj_as_string(event_name);

    var rc:RubyCore = this;
    var th:RbThread = rc.GET_THREAD();
    var block:RbBlock = vm_insnhelper_c.GET_BLOCK_PTR(GET_THREAD().cfp);

    var blockval:Value = rc.Qnil;
    // make Proc object
    if (block.proc == null) {
      var proc:RbProc;

      blockval = rc.vm_c.vm_make_proc(th, th.cfp, block, rc.proc_c.rb_cProc);

      proc = rc.vm_c.GetProcPtr(blockval);
      //block.v = proc.block;
    }
    else {
      blockval = block.proc;
    }
    //orig_argv.set_at(iseq.arg_block, blockval); // Proc or nil

    dispatcher.addEventListener(str.string, function (e:Event):void {
      rc.bare_block_call(blockval, rc.wrap_flash_obj(e));
    });

    return Qnil;
  }


  public function
  bare_block_call(block:Value, ...args):void
  {
    //var argv:StackPointer = new StackPointer(args, 0);
    //eval_c.ruby_run_node(block);
    //vm_c.rb_iseq_eval(iseq);
    var th:RbThread = GET_THREAD();
    //vm_insnhelper_c.vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_TOP, Qnil, null,
    //              null, null, 0, th.stack, null, 1);

    //vm_c.rb_vm_set_finish_env(th);

    var rc:RubyCore = this;

    var empty_iseq_array:Array = [
      "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
      {arg_size:0, local_size:1, stack_max:4},
      "<compiled>", "<compiled>",
      "top",
      [],
      0,
      [
        ["break", rc.Qnil, "label_19", "label_27", "label_27", 0],
      ],
      [
        ["putspecialobject", 1],
        ["putspecialobject", 2],
        ["putobject", "callback"],
        ["putiseq",
          [
            "YARVInstructionSequence/SimpleDataFormat", 1, 1, 1,
            {arg_size:2, local_size:3, stack_max:2},
            "callback", "<compiled>",
            "method",
            ["e", "p"],
            2,
            [],
            [
              ["getlocal", 2],
              ["getlocal", 3],
              ["send", "call", 1, rc.Qnil, 0, rc.Qnil],
              ["leave"],
            ]
          ]
        ],
        ["send", "core#define_method", 3, rc.Qnil, 0, rc.Qnil],
        ["pop"],
        "label_19",
        ["putnil"],
        // Loop and push args
        ["putobject", args[0]],
        ["putobject", block],
        ["send", "callback", 2, rc.Qnil, 8, rc.Qnil],
        "label_27",
        ["leave"],
      ],
    ];

    var iseqval:Value = iseqval_from_array(empty_iseq_array);
    var iseq:RbISeq = iseq_c.GetISeqPtr(iseqval);

    vm_c.rb_iseq_eval(iseqval);

  }

  protected function
  wait_func(recv:Value, time:RInt):Value
  {
    var t:Timer = new Timer(time.value*1000, 1);
    var rc:RubyCore = this;
    var th:RbThread = rc.GET_THREAD();
    t.addEventListener(TimerEvent.TIMER,
      function(e:TimerEvent):void {
        rc.restart_thread(th);
      });

    t.start();
    return Qpause;
  }

  protected function
  restart_thread(th:RbThread):void
  {
    if (GET_THREAD() != th) {
      error_c.rb_bug("Different thread restarted.");
    }
    if (th.cfp.sp.get_at(0) != Qpause) {
      error_c.rb_bug("Tried to restart a thread that was not paused.");
    } else {
      th.cfp.sp.push(Qnil);
    }
    vm_evalbody_c.vm_eval(th, Qnil);
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
    eval_c.ruby_init();
    eval_c.ruby_run_node(n);
  }

  // inits.c:59
  public function
  rb_call_inits():void
  {

    // TODO: @skipped
    //Init_RandomSeed();
    parse_y.Init_sym();
    ID_ALLOCATOR = parse_y.rb_intern("allocate");
    variable_c.Init_var_tables();
    object_c.Init_Object();
    vm_c.Init_top_self();
    //Init_Encoding();
    //Init_Comparable();
    enum_c.Init_Enumerable();
    //Init_Precision();
    string_c.Init_String();
    error_c.Init_Exception();
    eval_c.Init_eval();
    //Init_jump();
    numeric_c.Init_Numeric();
    //Init_Bignum();
    //Init_syserr();
    array_c.Init_Array();
    hash_c.Init_Hash();
    //Init_Struct();
    //Init_Regexp();
    //Init_pack();
    //Init_transcode();
    //Init_marshal();
    //Init_Range();
    io_c.Init_IO();
    //Init_Dir();
    //Init_Time();
    //Init_Random();
    //Init_signal();
    //Init_process();
    //Init_load();
    proc_c.Init_Proc();
    proc_c.Init_Binding();
    //Init_Math();
    //Init_GC();
    //Init_Enumerator();
    vm_c.Init_VM();
    iseq_c.Init_ISeq();
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
    return gc_c.rb_data_object_alloc(klass, obj, mark, free);
  }

  // ruby.c:1465
  public function
  ruby_prog_init():void
  {
  }

  public var rb_mFlash:RClass;
  public var rb_mFlashDisplay:RClass;
  public var rb_mFlashText:RClass;

  public function
  init_flash_classes():void
  {
    rb_cFlashObject = class_c.rb_define_class("FlashObject", object_c.rb_cObject);
    class_c.rb_define_method(rb_cFlashObject, "method_missing", fo_method_missing, -1);
    class_c.rb_define_method(rb_cFlashObject, "responds_to?", fo_responds_to, 1);
    class_c.rb_define_method(rb_cFlashObject, "on", fo_on, 1);

    rb_cFlashClass = class_c.rb_define_class("FlashClass", object_c.rb_cObject);
    class_c.rb_define_method(rb_cFlashClass, "new", fc_new_obj, -1);
    class_c.rb_define_method(rb_cFlashClass, "method_missing", fo_method_missing, -1);
    class_c.rb_define_method(rb_cFlashClass, "responds_to?", fo_responds_to, 1);

    rb_mFlash = class_c.rb_define_module("Flash");
    rb_mFlashDisplay = class_c.rb_define_module_under(rb_mFlash, "Display");
    variable_c.rb_const_set(rb_mFlashDisplay, parse_y.rb_intern("Sprite"), wrap_flash_class(Sprite));
    rb_mFlashText = class_c.rb_define_module_under(rb_mFlash, "Text");
    variable_c.rb_const_set(rb_mFlashText, parse_y.rb_intern("TextField"), wrap_flash_class(TextField));
    variable_c.rb_const_set(rb_mFlashText, parse_y.rb_intern("TextFormat"), wrap_flash_class(TextFormat));
  }

  public function
  fc_new_obj(argc:int, argv:StackPointer, recv:Value):Value
  {
    var flash_class:Class = vm_c.GetCoreDataFromValue(recv);
    var retval:*;
    if (argc > 1) {
      var as3_args:Array = convert_array_to_as3(argc-1, argv.clone_down_stack(1));
      switch (as3_args.length) {
        case 1:
          retval = new flash_class(as3_args[0]);
          break;
        case 2:
          retval = new flash_class(as3_args[0], as3_args[1]);
          break;
        case 3:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2]);
          break;
        case 4:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2], as3_args[3]);
          break;
        case 5:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2], as3_args[3], as3_args[4]);
          break;
        case 6:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2], as3_args[3], as3_args[4], as3_args[5]);
          break;
        case 7:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2], as3_args[3], as3_args[4], as3_args[5], as3_args[6]);
          break;
        case 8:
          retval = new flash_class(as3_args[0], as3_args[1], as3_args[2], as3_args[3], as3_args[4], as3_args[5], as3_args[6], as3_args[7]);
          break;
        default:
          error_c.rb_bug("too many arguments to Flash Class constructor");
          break;
      }
      retval = new flash_class(as3_args);
    } else {
      retval = new flash_class();
    }
    return convert_to_ruby_value(retval);
  }

  public function
  fo_method_missing(argc:int, argv:StackPointer, recv:Value):Value
  {
    var flash_obj:Object = vm_c.GetCoreDataFromValue(recv);
    var method_name:String = parse_y.rb_id2name(RSymbol(argv.get_at(0)).id);
    var attr_set:Boolean = false;
    if (method_name.charAt(method_name.length-1) == "=" && argc == 2) {
      method_name = method_name.substr(0, method_name.length-1);
      flash_obj[method_name] = convert_to_as3(argv.get_at(1));
      return argv.get_at(0);
    }
    var val:* = flash_obj[method_name];
    if (val is Function) {
      var retval:*;
      //var func:Function = Function(val);
      if (argc > 1) {
        var as3_args:Array = convert_array_to_as3(argc-1, argv.clone_down_stack(1));
        retval = val.apply(flash_obj, as3_args);
      } else {
        retval = val.call(flash_obj);
      }
      return convert_to_ruby_value(retval);
    } else {
      return convert_to_ruby_value(val);
    }

    return Qnil;
  }

  public function
  fo_responds_to(argc:int, argv:StackPointer, recv:Value):Value
  {
    var flash_obj:Object = vm_c.GetCoreDataFromValue(recv);
    var method_name:String = parse_y.rb_id2name(RSymbol(argv.get_at(0)).id);
    if (method_name.charAt(method_name.length-1) == "=") {
      method_name = method_name.substr(0, method_name.length-1);
      try {
        var v:* = flash_obj[method_name]
      } catch (e:Error) {
        return Qfalse;
      }
      return Qtrue;
    }
    try {
      var val:* = flash_obj[method_name];
    } catch (e:Error) {
      return Qfalse;
    }

    return Qtrue;
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
    } else if (val is RFloat) {
      return RFloat(val).float_value;
    } else if (val is Value) {
      var v:Value = Value(val);
      var type:uint = v.get_type();
      switch (type) {
        case Value.T_STRING:
          return RSTRING_PTR(v);
        case Value.T_DATA:
          return RData(v).data;
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
    if (val === undefined || val === null) {
      return Qnil;
    } else if (val is RProxy) {
      return val.ruby_value;
    } else if (val === true) {
      return Qtrue;
    } else if (val === false) {
      return Qfalse;
    } else if (val is String) {
      var str:RString = new RString(string_c.rb_cString);
      str.string = val;
      return str;
    } else if (val is int || val is uint) {
      return new RInt(val);
    } else if (val is Number) {
      return new RFloat(numeric_c.rb_cFloat, val);
    } else {
      return wrap_flash_obj(val);
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

  // node.h
  public function NEW_NODE(t:uint, a0:*, a1:*, a2:*):Node {
    return gc_c.rb_node_newnode(t, a0, a1, a2);
  }

  // node.h
  public function NEW_BLOCK(a:*):Node {
    return NEW_NODE(Node.NODE_BLOCK, a, null, null);
  }

  // node.h
  public function NEW_CFUNC(f:Function, c:int):Node {
    return NEW_NODE(Node.NODE_CFUNC, f, c, null);
  }

  // node.h
  public function NEW_IFUNC(f:Function, c:*):Node {
    return NEW_NODE(Node.NODE_IFUNC, f, c, null);
  }

  // node.h
  public function NEW_METHOD(n:Value,x:Value,v:uint):Node {
    return NEW_NODE(Node.NODE_METHOD, x, n, v);
  }

  // node.h
  public function NEW_FBODY(n:Value,i:int):Node {
    return NEW_NODE(Node.NODE_FBODY, i, n, null);
  }

  // node.h
  public function NEW_IVAR(v:int):Node {
    return NEW_NODE(Node.NODE_IVAR, v, null, null);
  }

  // node.h
  public function NEW_ATTRSET(a:int):Node {
    return NEW_NODE(Node.NODE_ATTRSET, a, null, null);
  }

  // ruby.h:794
  public function FL_ABLE(x:Value):Boolean
  { return !SPECIAL_CONST_P(x) && x.BUILTIN_TYPE() != Value.T_NODE; }

  // ruby.h:802
  public function OBJ_TAINTED(x:Value):Boolean
  { return (x.flags & Value.FL_TAINT) != 0; }
  public function OBJ_TAINT(x:Value):void
  { x.flags |= Value.FL_TAINT; }
  public function OBJ_UNTRUSTED(x:Value):Boolean
  { return (x.flags & Value.FL_UNTRUSTED) != 0; }
  public function OBJ_UNRUST(x:Value):void
  { x.flags |= Value.FL_UNTRUSTED; }
  public function OBJ_INFECT(x:Value, s:Value):void
  {
    if (FL_ABLE(x) && FL_ABLE(s)) {
      x.flags |= (x.flags & (Value.FL_TAINT | Value.FL_UNTRUSTED));
    }
  }

  public function OBJ_FROZEN(x:Value):Boolean
  { return (x.flags & Value.FL_FREEZE) != 0; }
  public function OBJ_FREEZE(x:Value):void
  { x.flags |= Value.FL_FREEZE; }

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
      return parse_y.rb_intern(RString(sym).string);
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
    if (obj == Qfalse) return object_c.rb_cFalseClass;

    if (FIXNUM_P(obj)) {
      return numeric_c.rb_cFixnum;
    }

    if (obj == Qnil)   return object_c.rb_cNilClass;
    if (obj == Qtrue)  return object_c.rb_cTrueClass;
    return RBasic(obj).klass;
  }

  public function
  BASIC_OP_UNREDEFINED_P(op:int):Boolean
  {
    return (vm_c.ruby_vm_redefined_flag & op) == 0;
  }

  public function
  FIXNUM_2_P(a:Value, b:Value):Boolean
  {
    return FIXNUM_P(a) && FIXNUM_P(b);
  }

  public function
  HEAP_CLASS_OF(obj:Value):RClass
  {
    return rb_class_of(obj);
  }

  public function
  CLASS_OF(v:Value):RClass
  {
    return rb_class_of(v);
  }

  public function
  FIX2LONG(x:Value):int
  {
    return RInt(x).value;
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
    var iseqval:Value = iseq_c.rb_iseq_new(null, string_c.rb_str_new2("<main>"),
                                              string_c.rb_str_new2("filename.rb"), Qfalse, RbVm.ISEQ_TYPE_TOP);

    // Get the iseq out and assign the function pointer
    var iseq:RbISeq = iseq_c.GetISeqPtr(iseqval);
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
      error_c.rb_bug("unknown iseq type: " + type_str);
    }

    parent = parent ? parent : Qfalse;

    // Pass in null for the node first
    var iseqval:Value = iseq_c.rb_iseq_new(null, string_c.rb_str_new2("<main>"),
                                              string_c.rb_str_new2("filename.rb"), parent, type);

    // Get the iseq out and assign the function pointer
    var iseq:RbISeq = iseq_c.GetISeqPtr(iseqval);
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
    var iseqval:Value = iseq_c.rb_iseq_new(null, string_c.rb_str_new2("<class:"+name+">"),
                                              string_c.rb_str_new2("filename.rb"),
                                              Qfalse, RbVm.ISEQ_TYPE_CLASS);
    var class_iseq:RbISeq = iseq_c.GetISeqPtr(iseqval);
    class_iseq.arg_size = arg_size;
    class_iseq.local_size = local_size;
    class_iseq.stack_max = stack_max;
    class_iseq.iseq_fn = func;

    return class_iseq;
  }

  public function
  method_iseq_from_func(name:String, arg_size:int, local_size:int, stack_max:int, func:Function):RbISeq
  {
    var iseqval:Value = iseq_c.rb_iseq_new(null, string_c.rb_str_new2(name),
                                              string_c.rb_str_new2("filename.rb"),
                                              Qfalse, RbVm.ISEQ_TYPE_METHOD);
    var class_iseq:RbISeq = iseq_c.GetISeqPtr(iseqval);
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
    error_c.rb_check_type(v, t);
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
    return parse_y.rb_intern2(str);
  }

  public function
  ruby_vm_verbose_ptr(vm:RbVm):Value
  {
    return vm.verbose;
  }

  public function
  ruby_verbose():Value
  {
    return ruby_vm_verbose_ptr(GET_VM());
  }

  // eval_intern.h:192
  public function
  SCOPE_TEST(f:int):Boolean
  {
    return (vm_c.vm_cref().nd_visi & f) != 0;
  }

  // eval_intern.h:193
  public function
  SCOPE_CHECK(f:int):Boolean
  {
    return vm_c.vm_cref().nd_visi == f;
  }

  // ruby.h:531
  public function
  ROBJECT_NUMIV(o:Value):int
  {
    if (RObject(o).ivptr) {
      return RObject(o).ivptr.length;
    } else {
      return 0;
    }
  }

  public function
  ROBJECT_IVPTR(o:Value):Array
  {
    return RObject(o).ivptr;
  }

  public function
  ROBJECT_IV_INDEX_TBL(o:Value):Object
  {
    return RObject(o).iv_index_tbl;
  }

  public function
  DOUBLE2NUM(dbl:Number):RFloat
  {
    return numeric_c.rb_float_new(dbl);
  }

  public function
  FL_TEST(v:Value, flag:uint):Boolean
  {
    return (v.flags & flag) != 0
  }

}
}

