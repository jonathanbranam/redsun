package ruby.internals
{
import flash.display.DisplayObject;

import ruby.RObject;


/**
 * Class for core ruby methods.
 */
public class RubyCore
{
  protected var rb_global_tbl:Object;
  protected var rb_class_tbl:Object;

  public var Qnil:Value;
  public var Qundef:Value;
  public var Qfalse:Value;
  public var Qtrue:Value;

  protected var autoload:int;
  protected var classpath:int;
  protected var tmp_classpath:int;

  public var rb_cBasicObject:RClass;
  public var rb_cObject:RClass;
  public var rb_cModule:RClass;
  public var rb_cClass:RClass;

  public var rb_cString:RClass;

  public var rb_cNilClass:RClass;
  public var rb_cData:RClass;
  public var rb_cTrueClass:RClass;
  public var rb_cFalseClass:RClass;


  public var rb_mKernel:RClass

  public var ID_ALLOCATOR:int;

  public var ruby_current_thread:RbThread;
  public var ruby_current_vm:RbVm;

  // vm_method.c:12
  public var __send__:int, object_id:int;
  public var removed:int, singleton_removed:int, undefined_:int, singleton_undefined:int;
  public var eqq:int, each_:int, aref:int, aset:int, match:int, missing:int;
  public var added:int, singleton_added:int;

  // various files static - object.c:35
  public var id_eq:int, id_eql:int, id_match:int, id_inspect:int, id_init_copy:int;
  public var id_to_s:int;

  // Modules
  public var parse_y:Parse_y;
  public var string_c:String_c;
  public var error_c:Error_c;
  public var vm_c:Vm_c;
  public var iseq_c:Iseq_c;
  public var io_c:IO_c;

  public function RubyCore()  {
  }

  public function run(docClass:DisplayObject, block:Function):void  {
    ruby_init();
    RGlobal.global.send_external(null, "const_set", "Document", docClass);
    RGlobal.global.send_external(null, "module_eval", block);
  }

  public function ruby_running():Boolean {
    return GET_VM().running;
  }

  public function ruby_run_node(n:Value):void {
    // Init_stack(n);
    ruby_cleanup(ruby_exec_node(n, null));
  }

  public function ruby_cleanup(ex:int):int {
    // cleanup, GC, stop threads, error hanlding
    return ex;
  }

  public function ruby_exec_node(n:Value, file:String):int {
    var iseq:Value = n;
    var th:RbThread = GET_THREAD();

    th.base_block = null;
    rb_iseq_eval(iseq);
    return 0;
  }

  public function GET_THREAD():RbThread {
    return ruby_current_thread;
  }

  public function vm_set_top_stack(th:RbThread, iseqval:Value):void {
    var iseq:RbISeq;

    iseq = iseq_c.GetISeqPtr(iseqval);

    if (iseq.type != RbVm.ISEQ_TYPE_TOP) {
      rb_raise(error_c.rb_eTypeError, "Not a toplevel InstructionSequence");
    }

    rb_vm_set_finish_env(th);

    vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_TOP, th.top_self, null, iseq.iseq_fn,
                  th.cfp.sp, null, iseq.local_size);
  }

  public function is_notop_id(id:int):Boolean {
    return id > Id.tLAST_TOKEN;
  }

  public function is_const_id(id:int):Boolean {
    return is_notop_id(id) && (id & Id.ID_SCOPE_MASK) == Id.ID_CONST;
  }

  public function rb_is_const_id(id:int):Boolean {
    if (is_const_id(id)) {
      return true;
    } else {
      return false;
    }
  }

  public function rb_define_const(klass:RClass, name:String, val:Value):void {
    var id:int = parse_y.rb_intern(name);

    if (!rb_is_const_id(id)) {
      rb_warn("rb_define_const: invalid name '"+name+"' for constant");
    }
    if (klass == rb_cObject) {
      // rb_secure(4);
    }
    rb_const_set(klass, id, val);
  }

  public function rb_define_global_const(name:String, val:Value):void {
    rb_define_const(rb_cObject, name, val);
  }

  public function rb_iseq_eval(iseqval:Value):Value {
    var th:RbThread = GET_THREAD();
    vm_set_top_stack(th, iseqval);
    //rb_define_global_const("TOPLEVEL_BINDING", rb_binding_new());
    return vm_eval_body(th);
  }

  public function vm_eval_body(th:RbThread):Value {
    var result:Value;
    var initial:Value;

    try {
      result = vm_eval(th, initial);
    } catch (e:Error) {
      trace("error: " +e.message);
      trace(e.getStackTrace());


      // Exception handling.

      // if state == TAG_RETRY
      // search catch_table for RETRY entry
      // etc.

      th.cfp = th.cfp_stack.pop();
      if (th.cfp.pc != finish_insn_seq) {
        trace("goto exception_handler");
        // goto exception_handler;
      } else {
        vm_pop_frame(th);
        // th.errinfo = err;
        // TH_POP_TAG2();
        // JUMP_TAG(state);
      }
    }

    return result;
  }

  public function vm_eval(th:RbThread, initial:Value):Value {
    var ret:Value;

    ret = th.cfp.pc.call(this, this, th, th.cfp);

    if (th.cfp.VM_FRAME_TYPE() != RbVm.VM_FRAME_MAGIC_FINISH) {
      rb_bug("cfp consistency error");
    }

    ret = th.cfp.sp.pop();
    //th.cfp++ // pop cf

    return ret;
  }

  public function vm_pop_frame(th:RbThread):void {
    // profile collection

    //th.cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th.cfp);
    th.cfp = th.cfp_stack.pop();
  }

  public function rb_bug(message:String):void {
    throw new Error("rb_bug: " + message);
  }

  protected function Init_var_tables():void {
    rb_class_tbl = {};
    rb_global_tbl = {};
    autoload = parse_y.rb_intern("__autoload__");
    classpath = parse_y.rb_intern("__classpath__");
    tmp_classpath = parse_y.rb_intern("__tmp_classpath__");
    ID_ALLOCATOR = parse_y.rb_intern("allocate");
  }

  public function main(n:Value):void  {
    //ruby_set_debug_option(getenv("RUBY_DEBUG"));
    //ruby_sysinit(&argc, &argv);
    //RUBY_INIT_STACK;
    ruby_init();
    ruby_run_node(n);
  }

  public function rb_call_inits():void {
    //Init_RandomSeed();
    //Init_sym();
    Init_var_tables();
    Init_Object();
    Init_top_self();
    //Init_Encoding();
    //Init_Comparable();
    //Init_Enumerable();
    //Init_Precision();
    //Init_String();
    error_c.Init_Exception();
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
    io_c.Init_IO();
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
    vm_c.Init_VM();
    iseq_c.Init_ISeq();
    //Init_Thread();
    //Init_Cont();
    //Init_Rational();
    //Init_Complex();
    //Init_version();
  }

  public function rb_obj_respond_to(obj:Value, id:int, priv:Boolean):Boolean {
    return true;
    /*
    var klass:RClass = CLASS_OF(obj);

    if (rb_method_basic_definition_p(klass, idRespond_to)) {
      return rb_method_boundp(klass, id, !priv);
    } else {
      var args:Array = new Array();
      var n:int = 0;
      args[n++] = ID2SYM(id);
      if (priv) {
        args[n++] = Qtrue;
      }
      return RTEST(rb_funcall2(obj, idRespond_to, n, args));
    }
    */
  }

  public function rb_respond_to(obj:Value, id:int):Boolean {
    return rb_obj_respond_to(obj, id, false);
  }

  public function obj_respond_to(argc:int, argv:Array, obj:Value):Value {
    return Qtrue;
    /*
    var mid:Value;
    var priv:Value;
    var id:int;

    var midRef:ByRef = new ByRef();
    var privRef:ByRef = new ByRef();

    rb_scan_args(argc, argv, "11", midRef, privRef);
    mid = midRef.v;
    priv = privRef.v;
    id = rb_to_id(mid);
    if (rb_method_boundp(CLASS_OF(obj), id, !RTEST(priv))) {
      return Qtrue;
    } else {
      return Qfalse;
    }
    */
  }

  public function Init_eval():void {
    Init_vm_eval();
    Init_eval_method();

  }

  public function RUBY_VM_PREVIOUS_CONTROL_FRAME(th:RbThread):RbControlFrame {
    return th.cfp_stack[th.cfp_stack.length-1];
  }

  public function rb_obj_classname(obj:Value):String {
    return rb_class2name(CLASS_OF(obj));
  }

  public function convert_type(val:Value, tname:String, method:String, raise:Boolean):Value {
    var m:int;

    m = parse_y.rb_intern(method);
    if (!rb_respond_to(val, m)) {
      if (raise) {
        rb_raise(error_c.rb_eTypeError, "can't convert "+
                  (NIL_P(val) ? "nil " : val == Qtrue ? "true" : val == Qfalse ? "false" : rb_obj_classname(val)) +
                  " into " + tname);
      } else {
        return Qnil;
      }
    }
    return rb_funcall(val, m, 0);
  }

  public function rb_convert_type(val:Value, type:int, tname:String, method:String):Value {
    var v:Value;

    if (val.get_type() == type) {
      return val;
    }
    v = convert_type(val, tname, method, true);
    if (v.get_type() != type) {
      var cname:String = rb_obj_classname(val);
      rb_raise(error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rb_obj_classname(v));
    }
    return v;
  }

  public function rb_check_convert_type(val:Value, type:int, tname:String, method:String):Value {
    var v:Value;

    if (val.get_type() == type && type != Value.T_DATA) {
      return val;
    }
    v = convert_type(val, tname, method, false);
    if (NIL_P(v)) {
      return Qnil;
    }
    if (v.get_type() != type) {
      var cname:String = rb_obj_classname(val);
      rb_raise(error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rb_obj_classname(v));
    }
    return v;
  }

  public function rb_check_string_type(str:Value):Value {
    str = rb_check_convert_type(str, Value.T_STRING, "String", "to_str");
    return str;
  }

  public function RSTRING_PTR(val:Value):String {
    if (val.get_type() == Value.T_STRING) {
      return RString(val).string;
    } else {
      return null;
    }
  }

  public function rb_inspect(val:Value):RString {
    var str:RString = new RString(rb_cString);
    str.string = "rb_inspect results for "+val;
    return str;
  }

  public function rb_to_id(name:Value):int {
    var tmp:Value;
    var id:int;

    switch (name.get_type()) {
      default:
        tmp = rb_check_string_type(name);
        if (NIL_P(tmp)) {
          rb_raise(error_c.rb_eTypeError, RSTRING_PTR(rb_inspect(name))+" is not a symbol");
        }
        name = tmp;
        // Intentional fall through
      case Value.T_STRING:
        name = string_c.rb_str_intern(name);
        // Intentional fall through
      case Value.T_SYMBOL:
        return SYM2ID(name);
    }
    return id;
  }

  public function send_internal(argc:int, argv:Array, recv:Value, scope:int):Value {
    var vid:Value;
    var self:Value = RUBY_VM_PREVIOUS_CONTROL_FRAME(GET_THREAD()).self;
    var th:RbThread = GET_THREAD();

    if (argc == 0) {
      rb_raise(error_c.rb_eArgError, "no method name given");
    }

    vid = argv.shift();

    return rb_call0(CLASS_OF(recv), recv, rb_to_id(vid), argc, argv, scope, self);
  }

  public function rb_f_send(argc:int, argv:Array, recv:Value):Value {
    return send_internal(argc, argv, recv, Node.NOEX_NOSUPER | Node.NOEX_PRIVATE);
  }

  public function rb_f_public_send(argc:int, argv:Array, recv:Value):Value {
    return send_internal(argc, argv, recv, Node.NOEX_PUBLIC);
  }

  // class.c:855
  public function rb_define_module_function(module:RClass, name:String, func:Function, argc:int):void {
    rb_define_private_method(module, name, func, argc);
    rb_define_singleton_method(module, name, func, argc);
  }

  // class.c:862
  public function rb_define_global_function(name:String, func:Function, argc:int):void {
    rb_define_module_function(rb_mKernel, name, func, argc);
  }

  public function Init_vm_eval():void {
    //rb_define_global_function("catch", rb_f_catch, -1);
    //rb_define_global_function("throw", rb_f_throw, -1);

    //rb_define_global_function("loop", rb_f_loop, 0);

    //rb_define_method(rb_cBasicObject, "instance_eval", rb_obj_instance_eval, -1);
    //rb_define_method(rb_cBasicObject, "instance_exec", rb_obj_instance_exec, -1);
    //rb_define_private_method(rb_cBasicObject, "method_missing", rb_method_missing, -1);

    rb_define_method(rb_cBasicObject, "__send__", rb_f_send, -1);
    rb_define_method(rb_mKernel, "send", rb_f_send, -1);
    rb_define_method(rb_mKernel, "public_send", rb_f_public_send, -1);

    //rb_define_method(rb_cModule, "module_exec", rb_mod_module_exec, -1);
    //rb_define_method(rb_cModule, "class_exec", rb_mod_module_exec, -1);

    //rb_define_global_function("caller", rb_f_caller, -1);

  }

  public function Init_eval_method():void {
    /*
    rb_define_method(rb_mKernel, "respond_to?", obj_respond_to, -1);

    rb_define_private_method(rb_cModule, "remove_method", rb_mod_remove_method, -1);
    rb_define_private_method(rb_cModule, "undef_method", rb_mod_undef_method, -1);
    rb_define_private_method(rb_cModule, "alias_method", rb_mod_alias_method, 2);
    rb_define_private_method(rb_cModule, "public", rb_mod_public, -1);
    rb_define_private_method(rb_cModule, "protected", rb_mod_protected, -1);
    rb_define_private_method(rb_cModule, "private", rb_mod_private, -1);
    rb_define_private_method(rb_cModule, "module_function", rb_mod_modfunc, -1);

    rb_define_method(rb_cModule, "method_defined?", rb_mod_method_defined, 1);
    rb_define_method(rb_cModule, "public_method_defined?", rb_mod_public_method_defined, 1);
    rb_define_method(rb_cModule, "private_method_defined?", rb_mod_private_method_defined, 1);
    rb_define_method(rb_cModule, "protected_method_defined?", rb_mod_protected_method_defined, 1);
    rb_define_method(rb_cModule, "public_class_method", rb_mod_public_method, -1);
    rb_define_method(rb_cModule, "private_class_method", rb_mod_private_method, -1);

    rb_define_singleton_method(rb_vm_top_self(), "public", top_public, -1);
    rb_define_singleton_method(rb_vm_top_self(), "private", top_private, -1);
    */

    object_id = parse_y.rb_intern_const("object_id");
    __send__ = parse_y.rb_intern_const("__send__");
    eqq = parse_y.rb_intern_const("===");
    each_ = parse_y.rb_intern_const("each");
    aref = parse_y.rb_intern_const("[]");
    aset = parse_y.rb_intern_const("[]=");
    match = parse_y.rb_intern_const("=~");
    missing = parse_y.rb_intern_const("method_missing");
    added = parse_y.rb_intern_const("method_added");
    singleton_added = parse_y.rb_intern_const("singleton_method_added");
    removed = parse_y.rb_intern_const("method_removed");
    singleton_removed = parse_y.rb_intern_const("singleton_method_removed");
    undefined_ = parse_y.rb_intern_const("method_undefined");
    singleton_undefined = parse_y.rb_intern_const("singleton_method_undefined");

  }

  public function GET_VM():RbVm {
    return ruby_current_vm;
  }

  public function rb_vm_top_self():Value {
    return GET_VM().top_self;
  }

  public function rb_obj_alloc(klass:RClass):Value {
    var obj:Value;

    if (klass.super_class == null && klass != rb_cBasicObject) {
      rb_raise(error_c.rb_eTypeError, "can't instantiate uninitialized class");
    }
    if (klass.is_singleton()) {
      rb_raise(error_c.rb_eTypeError, "can't create instance of singleton class");
    }
    obj = rb_funcall(klass, ID_ALLOCATOR, 0, null);
    if (rb_obj_class(obj) != rb_class_real(klass)) {
      rb_raise(error_c.rb_eTypeError, "wrong instance allocation");
    }

    return obj;
  }

  public function main_to_s(obj:Value):Value {
    return rb_str_new2("main");
  }

  public function rb_define_singleton_method(obj:Value, name:String, func:Function, argc:int):void {
    rb_define_method(rb_singleton_class(obj), name, func, argc);
  }

  public function Init_top_self():void {
    var vm:RbVm = GET_VM();

    vm.top_self = rb_obj_alloc(rb_cObject);
    rb_define_singleton_method(rb_vm_top_self(), "to_s", main_to_s, 0);
  }

  public function rb_thread_set_current_raw(th:RbThread):void {
    ruby_current_thread = th;
  }

  public function rb_thread_set_current(th:RbThread):void {
    rb_thread_set_current_raw(th);
    th.vm.running_thread = th;
  }

  public function vm_init2(vm:RbVm):void {
    vm.src_encoding_index = -1;
  }

  public function thread_recycle_stack(size:int):Array {
    return new Array();
  }

  public function vm_push_frame(th:RbThread, iseq:RbISeq, type:uint, self:Value, specval:Object,
                               pc:Function, sp:Array, lfp:Array, local_size:int):RbControlFrame
  {
    // rb_control_frame_t * const cfp = th->cfp = th->cfp - 1;
    var cfp:RbControlFrame = new RbControlFrame();
    th.cfp_stack.push(th.cfp);
    th.cfp = cfp;
    var i:int;

    for (i = 0; i < local_size; i++) {
      sp[i] = Qnil;
    }

    if (lfp == null) {
      lfp = sp;
    }

    cfp.pc = pc;
    cfp.sp = sp; // sp + 1
    cfp.bp = sp; // sp + 1
    cfp.iseq = iseq;
    cfp.flag = type;
    cfp.self = self;
    cfp.lfp = lfp;
    cfp.dfp = sp;
    cfp.proc = null;

    return cfp;
  }

  public function th_init2(th:RbThread, self:Value):void {
    th.self = self;

    th.stack_size = RbVm.RUBY_VM_THREAD_STACK_SIZE;
    th.stack = thread_recycle_stack(th.stack_size);

    th.cfp_stack = new Array();
    //th.cfp = new RbControlFrame();

    vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_TOP, Qnil, null, null, th.stack, null, 1);

    th.status = RbThread.THREAD_RUNNABLE;
    th.errinfo = Qnil;
    th.last_status = Qnil;
  }

  public function ruby_thread_init_stack(th:RbThread):void {
    // native thread init
  }

  public function th_init(th:RbThread, self:Value):void {
    th_init2(th, self);
  }

  public function GetThreadPtr(obj:*):RbThread {
    return RbThread(obj);
  }

  public function ruby_thread_init(self:Value):Value {
    var th:RbThread;
    var vm:RbVm = GET_THREAD().vm;
    th = GetThreadPtr(self);

    th_init(th, self);
    th.vm = vm;

    th.top_wrapper = null;
    th.top_self = rb_vm_top_self();

    return self;
  }

  public function
  GetCoreDataFromValue(obj:Value):*
  {
    return RData(obj).data;
  }

  public function rb_data_object_alloc(klass:RClass, datap:*, dmark:Function, dfree:Function):Value {
    var data:RData = new RData(klass);

    data.flags = Value.T_DATA;
    data.data = datap;
    data.dfree = dfree;
    data.dmark = dmark;

    return data;
  }

  public function Data_Wrap_Struct(klass:RClass, obj:*, mark:Function, free:Function):Value {
    return rb_data_object_alloc(klass, obj, mark, free);
  }

  protected function thread_alloc(klass:RClass):Value {
    var obj:Value;
    obj = Data_Wrap_Struct(klass, new RbThread(), null/*rb_thread_mark*/, null/*thread_free*/);

    return obj;
  }

  public function ruby_thread_alloc(klass:RClass):Value {
    var self:Value = thread_alloc(klass);
    ruby_thread_init(self);
    return self;
  }

  public function Init_BareVM():void {
    var th:RbThread = new RbThread();
    var vm:RbVm = new RbVm();
    rb_thread_set_current_raw(th);

    vm_init2(vm);

    ruby_current_vm = vm;

    th_init2(th, null);

    th.vm = vm;
    ruby_thread_init_stack(th);
  }

  public function Init_heap():void {
  }

  public function ruby_prog_init():void {
  }

  public function ruby_init():void {
    parse_y = new Parse_y(this);
    string_c = new String_c(this);
    error_c = new Error_c(this);
    vm_c = new Vm_c(this);
    iseq_c = new Iseq_c(this);
    io_c = new IO_c(this);

    parse_y.string_c = string_c;
    string_c.parse_y = parse_y;
    string_c.error_c = error_c;
    iseq_c.vm_c = vm_c;
    vm_c.iseq_c = iseq_c;

    io_c.parse_y = parse_y;
    io_c.error_c = error_c;

    Qnil = new RNil();
    Qtrue = new RTrue();
    Qfalse = new RFalse();
    Qundef = new RUndef();


    //Init_stack(&state);
    Init_BareVM();
    Init_heap();
    rb_call_inits();
    ruby_prog_init();

    GET_VM().running = true;
  }

  protected function define_flash_classes():void {
    /*
    define_class("Flash",
      RGlobal.global.send_external(null, "const_get", "Object"),
      function ():* {
      });
    */
  }

  protected function rb_class_boot(super_class:RClass):RClass {
    var klass:RClass = new RClass(null, super_class, rb_cClass);
    // OBJ_INFECT(klass, super_class);
    return klass;
  }

  protected function generic_ivar_set(obj:RObject, id:String, val:*):void {
  }

  protected function generic_ivar_get(obj:RObject, id:String):* {
    return undefined;//return obj.iv_tbl[id];
  }

  protected function rb_ivar_set(obj:RObject, id:int, val:*):void {
    if (obj is RClass) {
      obj.iv_tbl[id] = val;
    }

  }

  protected function rb_iv_set(obj:RObject, name:String, val:*):void {
    rb_ivar_set(obj, parse_y.rb_intern(name), val);
  }

  protected function rb_name_class(klass:RClass, id:int):void {
    rb_iv_set(klass, "__classid__", ID2SYM(id));
    klass.name = parse_y.rb_id2name(id);
  }

  protected function rb_const_set(obj:RObject, id:int, val:*):void {
    obj.iv_tbl[id] = val;
  }

  protected function boot_defclass(name:String, super_class:RClass):RClass {
    var obj:RClass = rb_class_boot(super_class);
    var id:int = parse_y.rb_intern(name);
    rb_name_class(obj, id);
    rb_class_tbl[id] = obj;
    rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
    return obj;
  }

  protected function rb_singleton_class_attached(klass:RClass, obj:RObject):void {
    if (klass.is_singleton()) {
      var attached:int = parse_y.rb_intern("__attached__");
      klass.iv_tbl[attached] = obj;
    }
  }

  protected function rb_class_real(cl:RClass):RClass {
    if (!cl) {
      return null;
    }
    while (cl.is_singleton() || cl.is_include_class()) {
      cl = RClass(cl).super_class;
    }
    return cl;
  }

  protected function rb_make_metaclass(obj:RObject, super_class:RClass):RClass {
    if (obj.is_class() && RClass(obj).is_singleton()) {
      return obj.klass = rb_cClass;
    } else {
      var klass:RClass = rb_class_boot(super_class);
      var s:uint = RClass.FL_SINGLETON;
      klass.flags |= RClass.FL_SINGLETON;
      klass.flags = klass.flags | s;
      if (obj.get_type() == Value.T_CLASS) {
        klass.name = RClass(obj).name+"Singleton";
      }
      obj.klass = klass;
      rb_singleton_class_attached(klass, obj);

      var metasuper:RClass = rb_class_real(super_class).klass;
      if (metasuper) {
        klass.klass = metasuper;
      }
      return klass;
    }
  }

  protected function rb_warn(text:String):void {
    trace(text);
  }

  protected function rb_error_frozen(text:String):void {
    throw new Error("Frozen " + text);
  }

  protected function rb_add_method(klass:RClass, mid:int, node:Node, noex:uint):void {
    if (!klass) {
      klass = rb_cObject;
    }
    if (!klass.is_singleton() &&
      node && node.nd_type() != Node.NODE_ZSUPER &&
      (mid == parse_y.rb_intern("initialize") || mid == parse_y.rb_intern("initialize_copy")))
    {
      noex |= Node.NOEX_PRIVATE;
    } else if (klass.is_singleton() && node
      && node.nd_type() == Node.NODE_CFUNC && mid == parse_y.rb_intern("allocate")) {
        rb_warn("defining %s.allocate is deprecated; use rb_define_alloc_func()");
        mid = ID_ALLOCATOR;
    }
    if (klass.is_frozen()) {
      rb_error_frozen("class/module");
    }
    //rb_clear_cache_by_id(mid);

    var body:Node;

    if (node) {
      body = NEW_FBODY(NEW_METHOD(node, klass, NOEX_WITH_SAFE(noex)), null);
    } else {
      body = null;
    }

    // check re-definition

    // SKIP FOR NOW

    klass.m_tbl[mid] = body;

    if (node && mid != ID_ALLOCATOR && ruby_running()) {
      if (klass.is_singleton()) {
        rb_funcall(rb_iv_get(klass, "__attached__"), singleton_added, 1, ID2SYM(mid));
      } else {
        rb_funcall(klass, added, 1, ID2SYM(mid));
      }
    }
  }

  public function ID2SYM(x:int):Value {
    var sym:RSymbol = new RSymbol();
    sym.id = x;
    return sym;
  }

  protected function rb_node_newnode(type:uint, a0:*, a1:*, a2:*):Node {
    var n:Node = new Node();//rb_newobj();

    n.flags |= Value.T_NODE;
    n.nd_set_type(type);

    n.u1 = a0;
    n.u2 = a1;
    n.u3 = a2;

    return n;
  }

  protected function NOEX_SAFE(n:uint):uint {
    return (n >> 8) & 0x0F;
  }

  protected function NOEX_WITH(n:uint, s:uint):uint {
    return (s << 8) | n | (ruby_running() ? 0 : Node.NOEX_BASIC);
  }

  protected function NOEX_WITH_SAFE(n:uint):uint {
    return NOEX_WITH(n, rb_safe_level());
  }

  protected function NEW_NODE(t:uint, a0:*, a1:*, a2:*):Node {
    return rb_node_newnode(t, a0, a1, a2);
  }

  protected function NEW_CFUNC(f:Function, c:int):Node {
    return NEW_NODE(Node.NODE_CFUNC, f, c, null);
  }

  protected function NEW_METHOD(n:Value,x:Value,v:uint):Node {
    return NEW_NODE(Node.NODE_METHOD, x, n, v);
  }

  protected function NEW_FBODY(n:Value,i:Value):Node {
    return NEW_NODE(Node.NODE_FBODY, i, n, null);
  }

  protected function rb_safe_level():int {
    return 0;
    //return GET_THREAD()->safe_level;
  }

  public function
  rb_define_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }

  protected function rb_define_protected_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PROTECTED);
  }

  protected function rb_define_private_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PRIVATE);
  }

  protected function ivar_get(obj:Value, id:int, warn:Boolean):* {
    var val:*;

    switch (obj.get_type()) {
      case Value.T_OBJECT:
        val = RObject(obj).iv_tbl[id];
        if (val != undefined && val != Qundef) {
          return val;
        }
        break;
      case Value.T_CLASS:
      case Value.T_MODULE:
        val = RObject(obj).iv_tbl[id];
        if (val != undefined) {
          return val;
        }
        break;
      default:
        //if (FL_TEST(obj, FL_EXIVAR) || rb_special_const_p(obj)) {
        //  return generic_ivar_get(obj, id, warn);
        //}
        break;
    }
    return Qnil;
  }

  protected function rb_ivar_get(obj:RObject, id:int):* {
   return ivar_get(obj, id, true);
  }

  protected function rb_iv_get(obj:RObject, name:String):* {
    return rb_ivar_get(obj, parse_y.rb_intern(name));
  }

  protected function rb_singleton_class(obj:Value):RClass {
    // Special casing skipped

    var klass:RClass;

    var oobj:RObject = RObject(obj);
    if (oobj.klass.is_singleton() && rb_iv_get(oobj.klass, "__attached__") == obj) {
      klass = oobj.klass;
    } else {
      klass = rb_make_metaclass(oobj, oobj.klass);
    }
    // Taint, trust, frozen checks skipped
    return klass;
  }

  protected function rb_define_alloc_func(klass:RClass, func:Function):void {
    // Check_Type(klass, T_CLASS);
    rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, NEW_CFUNC(func, 0), Node.NOEX_PRIVATE);
  }

  protected function rb_class_allocate_instance(klass:RClass):RObject {
    var obj:RObject = new RObject(klass);
    obj.flags = Value.T_OBJECT;
    return obj;
  }

  protected function rb_obj_equal(obj1:Value, obj2:Value):Value {
    if (obj1 == obj2) {
      return Qtrue;
    } else {
      return Qfalse;
    }
  }

  protected function RTEST(v:Value):Boolean {
    //  (((VALUE)(v) & ~Qnil) != 0)
    return v != null && v != Qnil;
  }

  public function NIL_P(v:Value):Boolean {
    return v == Qnil;
  }

  protected function rb_obj_not(obj:Value):Value {
    return RTEST(obj) ? Qfalse : Qtrue;
  }

  // class.c:380
  public function rb_include_module(klass:RClass, module:RClass):void {
    var p:RClass, c:RClass;
    var changed:Boolean = false;

    // frozen, untrusted stuff

    if (module.get_type() != Value.T_MODULE) {
      // Check_Type(module, T_MODULE);
    }

    // OBJ_INFECT(klass, module);
    c = klass;
    while (module) {
      var superclass_seen:Boolean = false;

      if (klass.m_tbl == module.m_tbl) {
        rb_raise(error_c.rb_eArgError, "cyclic include detected");
      }
      var skip:Boolean = false;
      // ignore if the module included already in superclasses
      for (p = klass.super_class; p != null; p = p.super_class) {
        switch (p.BUILTIN_TYPE()) {
          case Value.T_ICLASS:
            if (p.m_tbl == module.m_tbl) {
              if (!superclass_seen) {
                c = p; // move insertion point
                // GOTO SKIP
                skip = true;
                break;
              }
            }
            break;
          case Value.T_CLASS:
            superclass_seen = true;
            break;
        }
        if (skip) {
          break;
        }
      }
      if (!skip) {
        c = c.super_class = include_class_new(module, c.super_class);
        changed = true;
      }
      // skip:
      module = module.super_class;
    }
    if (changed) {
      // rb_clear_cache();
    }
  }

  // class.c:354
  protected function include_class_new(module:RClass, super_class:RClass):RClass {
    var klass:RClass = new RClass(null, super_class, rb_cClass);

    if (module.BUILTIN_TYPE() == Value.T_ICLASS) {
      module = module.klass;
    }
    if (!module.iv_tbl) {
      module.iv_tbl = new Object();
    }

    klass.iv_tbl = module.iv_tbl;
    klass.m_tbl = module.m_tbl;
    klass.super_class = super_class;
    if (module.get_type() == Value.T_ICLASS) {
      klass.klass = module.klass;
    } else {
      klass.klass = module;
      klass.name = module.name+"IncludeClass";
    }
    // OBJ_INFECT(klass, module);
    // OBJ_INFECT(klass, module);

    return klass;
  }

  // class.c:313
  public function rb_define_module(name:String):RClass {
    var module:RClass;
    var id:int;
    var val:Value;

    id = parse_y.rb_intern(name);
    if (rb_const_defined(rb_cObject, id)) {
      val = rb_const_get(rb_cObject, id);
      if (val.get_type() == Value.T_MODULE) {
        return RClass(val);
      }
      rb_raise(error_c.rb_eTypeError, rb_obj_classname(module)+" is not a module");
    }
    module = rb_define_module_id(id);
    rb_class_tbl[id] = module;
    rb_const_set(rb_cObject, id, module);

    return module;
  }

  // class.c:302
  public function rb_define_module_id(id:int):RClass {
    var mdl:RClass;

    mdl = rb_module_new();
    rb_name_class(mdl, id);

    return mdl;
  }

  // class.c:292
  public function rb_module_new():RClass {
    var mdl:RClass = new RClass(null, null, rb_cModule);
    mdl.flags = Value.T_MODULE;
    return mdl;
  }

  protected function Init_Object():void {
    rb_cBasicObject = boot_defclass("BasicObject", null);
    rb_cObject = boot_defclass("Object", rb_cBasicObject);
    rb_cModule = boot_defclass("Module", rb_cObject);
    rb_cClass = boot_defclass("Class", rb_cModule);

    var metaclass:RClass;
    metaclass = rb_make_metaclass(rb_cBasicObject, rb_cClass);
    metaclass = rb_make_metaclass(rb_cObject, metaclass);
    metaclass = rb_make_metaclass(rb_cModule, metaclass);
    metaclass = rb_make_metaclass(rb_cClass, metaclass);

    rb_define_private_method(rb_cBasicObject, "initialize", rb_obj_dummy, 0);
    rb_define_alloc_func(rb_cBasicObject, rb_class_allocate_instance);
    rb_define_method(rb_cBasicObject, "==", rb_obj_equal, 1);
    rb_define_method(rb_cBasicObject, "equal?", rb_obj_equal, 1);
    rb_define_method(rb_cBasicObject, "!", rb_obj_not, 0);

    //rb_define_method(rb_cClass, "allocate", rb_obj_alloc, 0);

    rb_mKernel = rb_define_module("Kernel");
    rb_include_module(rb_cObject, rb_mKernel);
    rb_define_private_method(rb_cClass, "inherited", rb_obj_dummy, 1);
    rb_define_private_method(rb_cModule, "included", rb_obj_dummy, 1);
    rb_define_private_method(rb_cModule, "extended", rb_obj_dummy, 1);
    rb_define_private_method(rb_cModule, "method_added", rb_obj_dummy, 1);
    rb_define_private_method(rb_cModule, "method_removed", rb_obj_dummy, 1);
    rb_define_private_method(rb_cModule, "method_undefined", rb_obj_dummy, 1);

    rb_define_method(rb_mKernel, "to_s", rb_any_to_s, 0);

    // Lots of kernel methods

    rb_cNilClass = rb_define_class("NilClass", rb_cObject);
    // nilclass methods
    rb_define_global_const("NIL", Qnil);

    // Lots of module methods

    rb_cData = rb_define_class("Data", rb_cObject);
    // undef alloc func

    rb_cTrueClass = rb_define_class("TrueClass", rb_cObject);
    // setup trueclass
    rb_define_global_const("TRUE", Qtrue);

    rb_cFalseClass = rb_define_class("FalseClass", rb_cObject);
    // setup falseclass
    rb_define_global_const("FALSE", Qtrue);

    id_eq = parse_y.rb_intern("==");
    id_eql = parse_y.rb_intern("eql?");
    id_match = parse_y.rb_intern("=~");
    id_inspect = parse_y.rb_intern("inspect");
    id_init_copy = parse_y.rb_intern("initialize_copy");

    id_to_s = parse_y.rb_intern("to_s");

  }

  public function putspecialobject(stack:Array, id:uint):void
  {
    switch (id) {
    case 2:
      stack.push(rb_cObject);
      break;
    }
  }

  public function rb_raise(type:RClass, desc:String):void {
    throw new Error(type.toString() + desc);
  }

  public function rb_const_defined_at(cbase:RClass, id:int):Boolean {
    return false;
  }

  public function rb_const_get_at(cbase:RClass, id:int):Value {
    return null;
  }

  public function str_new(klass:RClass, str:String):RString {
    var res:RString = new RString(klass);
    res.string = str;
    return res;
  }

  public function rb_str_dup(str:RString):RString {
    var dup:RString = new RString(str.klass);
    dup.string = str.string;
    return dup;
  }

  public function rb_str_cat2(str:RString, ptr:String):RString {
    str.string += ptr;
    return str;
  }

  public function rb_str_new(str:String):RString {
    return str_new(rb_cString, str);
  }

  public function rb_str_new_cstr(str:String):RString {
    return str_new(rb_cString, str);
  }

  public function rb_str_new2(str:String):RString {
    return rb_str_new_cstr(str);
  }

  public function find_class_path(klass:RClass):Value {
    // Loop through all defined constants searching for one that points at this class.
    // Only needed for anonymous classes that are then queried for their names
    return Qnil;
  }

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

  public function rb_enc_str_new(ptr:String, enc:String):Value {
    var str:RString = rb_str_new(ptr);
    // rb_enc_associate(str, enc);
    return str;
  }

  public function classname(klass:RClass):Value {
    var path:Value = Qnil;

    if (!klass) {
      klass = rb_cObject;
    }
    if (klass.iv_tbl[classpath] == undefined) {
      var classid:int = parse_y.rb_intern("__classid__");

      if (klass.iv_tbl[classid] == undefined) {
        return find_class_path(klass);
      }
      path = klass.iv_tbl[classid];
      path = rb_str_dup(parse_y.rb_id2str(SYM2ID(path)));
      // OBJ_FREEZE(path);
      klass.iv_tbl[classpath] = path;
      delete klass.iv_tbl[classid];

    } else {
      path = klass.iv_tbl[classpath];
    }
    if (!path.is_string()) {
      rb_bug("class path is not set properly");
    }
    return path;
  }

  public function rb_obj_class(obj:Value):RClass {
    return rb_class_real(CLASS_OF(obj));
  }

  public function rb_class_name(klass:RClass):Value {
    return rb_class_path(rb_class_real(klass));
  }

  public function rb_class2name(klass:RClass):String {
    return RString(rb_class_name(klass)).string;
  }

  public function rb_class_path(klass:RClass):Value {
    var path:Value = classname(klass);

    if (!NIL_P(path)) {
      return path;
    }
    if (klass.iv_tbl[tmp_classpath] != undefined) {
      return path;
    } else {
      var s:String = "Class";
      if (klass.is_module()) {
        if (rb_obj_class(klass) == rb_cModule) {
          s = "Module";
        } else {
          s = rb_class2name(klass.klass);
        }
      }
      path = rb_str_new("#<"+s+":"+klass.toString()+">");
      // OBJ_FREEZE(path)
      rb_ivar_set(klass, tmp_classpath, path);

      return path;
    }
  }

  public function rb_set_class_path(klass:RClass, under:RClass, name:String):void {
    var str:RString;

    if (under == rb_cObject) {
      str = rb_str_new2(name);
    } else {
      str = rb_str_dup(RString(rb_class_path(under)));
      rb_str_cat2(str, "::");
      rb_str_cat2(str, name);
    }
    // OBJ_FREEZE(str);
    rb_ivar_set(klass, classpath, str);
  }

  public function rb_class_new(super_class:RClass):RClass {
    // Check_Type(super_class, T_CLASS);
    // rb_check_inheritable(super_class);
    if (super_class == rb_cClass) {
      rb_raise(error_c.rb_eTypeError, "can't make subclass of Class");
    }
    return rb_class_boot(super_class);
  }

  // variable.c:1654
  public function rb_const_defined(klass:RClass, id:int):Boolean {
    return rb_const_defined_0(klass, id, false, true);
  }

  // variable.c:1439
  public function rb_const_get_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Value {
    var value:Value, tmp:RClass;
    var mod_retry:Boolean = false;
    var loop:Boolean;

    tmp = klass;

    // retry:
    do {
      loop = false;

      while (RTEST(tmp)) {
        if (tmp.iv_tbl && tmp.iv_tbl[id]) {
          value = tmp.iv_tbl[id];
          if (value == Qundef) {// && NIL_P(autoload_file(klass, id))) {
            continue;
          }
          if (exclude && tmp == rb_cObject && klass != rb_cObject) {
            rb_warn("toplevel constant "+parse_y.rb_id2name(id)+" referenced by "+
                    rb_class2name(klass)+"::"+parse_y.rb_id2name(id));
          }
          return value;
        }
        if (!recurse && klass != rb_cObject) {
          break;
        }
        tmp = tmp.super_class;
      }
      if (!exclude && !mod_retry && klass.BUILTIN_TYPE() == Value.T_MODULE) {
        mod_retry = true;
        tmp = rb_cObject;
        // goto retry;
        loop = true;
      }
    } while (loop);

    return const_missing(klass, id);
  }

  // variable.c:1270
  public function const_missing(klass:RClass, id:int):Value {
    return rb_funcall(klass, parse_y.rb_intern("const_missing"), 1, ID2SYM(id));
  }

  // variable.c:1477
  public function rb_const_get(klass:RClass, id:int):Value {
    return rb_const_get_0(klass, id, false, true);
  }

  // variable.c:1623
  public function rb_const_defined_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Boolean {
    var value:Value, tmp:RClass;
    var mod_retry:Boolean = false;
    var loop:Boolean;

    tmp = klass;

    // retry:
    do {
      loop = false;

      while (tmp) {
        if (tmp.iv_tbl && tmp.iv_tbl[id]) {
          value = tmp.iv_tbl[id];
          if (value == Qundef) {// && NIL_P(autoload_file(klass, id))) {
            return false;
          } else {
            return true;
          }
        }
        if (!recurse && klass != rb_cObject) {
          break;
        }
        tmp = tmp.super_class;
      }
      if (!exclude && !mod_retry && klass.BUILTIN_TYPE() == Value.T_MODULE) {
        mod_retry = true;
        tmp = rb_cObject;
        // goto retry;
        loop = true;
      }
    } while (loop);
    return false;
  }

  // error.c:621
  public function rb_name_error(id:int, str:String):void {
    // This isn't right at all
    rb_raise(error_c.rb_eNameError, str);
  }

  // class.c:263
  public function
  rb_define_class_under(outer:RClass, name:String, super_class:RClass):RClass
  {
    var klass:RClass;
    var id:int;

    id = parse_y.rb_intern(name);
    if (rb_const_defined_at(outer, id)) {
      var val:Value = rb_const_get_at(outer, id);
      if (val.get_type() != Value.T_CLASS) {
        rb_raise(error_c.rb_eTypeError, name+" is not a class");
      }
      klass = RClass(val);
      if (rb_class_real(klass.super_class) != super_class) {
        rb_name_error(id, name+" is already defined");
      }
      return klass;
    }
    if (!super_class) {
      rb_warn("no super class for '"+rb_class2name(outer)+"::"+name+"', Object assumed");
    }
    klass = rb_define_class_id(id, super_class);
    rb_set_class_path(klass, outer, name);
    rb_const_set(outer, id, klass);
    rb_class_inherited(super_class, klass);

    return klass;
  }

  // class.c:234
  public function rb_define_class(name:String, super_class:RClass):RClass {
    var klass:RClass;
    var val:Value;
    var id:int;

    id = parse_y.rb_intern(name);
    if (rb_const_defined(rb_cObject, id)) {
      val = rb_const_get(rb_cObject, id);
      if (val.get_type() != Value.T_CLASS) {
        rb_raise(error_c.rb_eTypeError, name+" is not a class");
      }
      klass = RClass(val);
      if (rb_class_real(klass.super_class) != super_class) {
        rb_name_error(id, name+" is already defined");
      }
      return klass;
    }
    if (!super_class) {
      rb_warn("no super class for '"+name+"', Object assumed");
    }

    klass = rb_define_class_id(id, super_class);
    rb_class_tbl[id] = klass;
    rb_name_class(klass, id);
    rb_const_set(rb_cObject, id, klass);
    rb_class_inherited(super_class, klass);

    return klass;
  }

  public function rb_define_class_id(id:int, super_class:RClass):RClass {
    var klass:RClass;

    if (!super_class) {
      super_class = rb_cObject;
    }

    klass = rb_class_new(super_class);
    rb_make_metaclass(klass, super_class.klass);

    return klass;
  }

  public function rb_class_of(obj:Value):RClass {
    // Test for immediate objects and special values
    if (obj == Qnil)   return rb_cNilClass;
    if (obj == Qtrue)  return rb_cTrueClass;
    if (obj == Qfalse) return rb_cFalseClass;
    return RBasic(obj).klass;
  }

  public function CLASS_OF(v:Value):RClass {
    return rb_class_of(v);
  }

  public function vm_setup_method(th:RbThread, cfp:RbControlFrame, argc:int, blockptr:Value,
      flag:uint, iseqval:Value, recv:Value, klass:RClass):void
  {
    // various checks
    var iseq:RbISeq;
    var sp:Array = cfp.sp; // cfp->sp - argc

    iseq = iseq_c.GetISeqPtr(iseqval);

    vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_METHOD, recv, blockptr, iseq.iseq_fn, sp, null, 0);
  }

  protected var finish_insn_seq:Function = function (th:RbThread, cfp:RbControlFrame):Value { this.finish(); return this.Qnil; };

  public function rb_vm_set_finish_env(th:RbThread):Value {
    vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_FINISH, Qnil, th.cfp.lfp[0], null, th.cfp.sp, null, 1);
    th.cfp.pc = finish_insn_seq;
    return Qtrue;
  }

  // vm_eval.c:30
  public function vm_call0(th:RbThread, klass:RClass, recv:Value, id:int, oid:int, argc:int, argv:Array, body:Node, nosuper:int):Value {
    var val:Value = Qnil;
    var blockptr:RbBlock;

    if (th.passed_block) {
      blockptr = th.passed_block;
      th.passed_block = null;
    }

    var type:uint = body.nd_type();

    // shared vars:
    var reg_cfp:RbControlFrame;

    switch (type) {
    case Node.RUBY_VM_METHOD_NODE:{
      var iseqval:Value = body.nd_body();
      var i:int;

      rb_vm_set_finish_env(th);
      reg_cfp = th.cfp;

      /*
      CHECK_STATCK_OVERFLOW(reg_cfp, argc+1);

      *reg_cfp.sp++ = recv;
      for (i = 0; i < argc; i++) {
        *reg_cfp.sp++ = argv[i];
      }
      */

      vm_setup_method(th, reg_cfp, argc, blockptr, 0, iseqval, recv, klass);
      val = vm_eval_body(th);
      break;
    }
    case Node.NODE_CFUNC:
      //EXEC_EVENT_HOOK(th, RUBY_EVENT_C_CALL, recv, id, klass);
      {
        reg_cfp = th.cfp;
        var cfp:RbControlFrame = vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_CFUNC,
                                               recv, blockptr, null, reg_cfp.sp, null, 1);
        cfp.method_id = id;
        cfp.method_class = klass;

        val = call_cfunc(body.nd_cfnc(), recv, body.nd_argc(), argc, argv);

        if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
          rb_bug("cfp consistency error - call0");
          th.cfp = reg_cfp;
        }
        vm_pop_frame(th);
      }
      break;
    case Node.NODE_ATTRSET:
      break;
    case Node.NODE_IVAR:
      break;
    case Node.NODE_BMETHOD:
      break;
    default:
      rb_bug("unsupported: vm_call0("+ruby_node_name(body.nd_type())+")");
      break;
    }
    return val;
  }

  // vm_insnhelper.c:273
  protected function call_cfunc(func:Function, recv:Value, len:int, argc:int, argv:Array):Value {
    if (len >= 0 && argc != len) {
      rb_raise(error_c.rb_eArgError, "wrong number of arguments("+argc+" for "+len+")");
    }

    switch (len) {
      case -2:
        return Qnil;//func.call(this, recv, rb_ary_new4(argc, argv);
      case -1:
        return func.call(this, argc, argv, recv);
      case 0:
        return func.call(this, recv);
      case 1:
        return func.call(this, recv, argv[0]);
      case 2:
        return func.call(this, recv, argv[0], argv[1]);
      case 3:
        return func.call(this, recv, argv[0], argv[1], argv[2]);
      case 4:
        return func.call(this, recv, argv[0], argv[1], argv[2], argv[3]);
      case 5:
        return func.call(this, recv, argv[0], argv[1], argv[2], argv[3], argv[4]);
      default:
        rb_raise(error_c.rb_eArgError, "too many arguments("+len+")");
    }
    return Qnil; // not reached
  }

  public function vm_call_method(th:RbThread, cfp:RbControlFrame, num:int, blockptr:Value, flag:uint,
                                 id:int, mn:Node, recv:Value, klass:RClass):Value
  {
    var val:Value = Qundef;

    if (mn != null) {
      //if (mn.nd_noex() == 0) {
        var node:Node;

        node = mn.nd_body();

        switch (node.nd_type()) {
        case Node.RUBY_VM_METHOD_NODE: {
          vm_setup_method(th, cfp, num, blockptr, flag, node.nd_body(), recv, klass);
          return Qundef;
        }
        case Node.NODE_CFUNC: {
          val = vm_call_cfunc(th, cfp, num, id, recv, mn.nd_clss(), flag, node, blockptr);
        }
        }
      //}
    }

    return val;
  }

  // vm_insnhelper.c:361
  protected function
  vm_call_cfunc(th:RbThread, reg_cfp:RbControlFrame, num:int, id:int,
                recv:Value, klass:RClass, flag:uint, mn:Node, blockptr:Value):Value
  {
    var val:Value;

    // EXEC_EVENT_HOOK(th, RUBY_EVENT_C_CALL, recv, id, klass);
    {
      var cfp:RbControlFrame = vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_CFUNC,
                                             recv, blockptr, null, reg_cfp.sp, null, 1);
      cfp.method_id = id;
      cfp.method_class = klass;

      //reg_cfp.sp -= num + 1;
      var argv:Array = reg_cfp.sp.slice(reg_cfp.sp.length-num, reg_cfp.sp.length);
      reg_cfp.sp.length -= num+1;

      val = call_cfunc(mn.nd_cfnc(), recv, mn.nd_argc(), num, argv);

      if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
        rb_bug("cfp consistency error - send");
      }
      vm_pop_frame(th);
    }
    // EXEC_EVENT_HOOK(th, RUBY_EVENT_C_RETURN, recv, id, klass);

    return val;
  }

  public function ruby_node_name(type:uint):String {
    return "Node :" + type;
  }

  public function search_method(klass:RClass, id:int, klassp:RClass):Node {
    var body:Node = null;

    if (!klass) {
      return null;
    }

    while ((body = klass.m_tbl[id]) == null) {
      klass = klass.super_class;
      if (klass == null) {
        return null;
      }
    }

    return body;
  }

  public function rb_get_method_body(klass:RClass, id:int, idp:ByRef):Node {
    var fbody:Node;
    var body:Node;
    var method:Node;

    fbody = search_method(klass, id, null);
    if (!fbody || fbody.nd_body() == null) {
      // store empty info in cache
      return null;
    }

    method = fbody.nd_body();

    if (ruby_running()) {
      // Store in cache;
      body = method;
    } else {
      body = method;
    }

    if (idp) {
      idp.v = fbody.nd_oid();
    }

    return body;
  }

  // vm_eval.c:303
  public function rb_method_missing(argc:int, argv:Array, obj:Value):Value {
    var id:int;
    var exc:RClass = error_c.rb_eNoMethodError;
    var format:String = null;
    var th:RbThread = GET_THREAD();
    var last_call_status:int = th.method_missing_reason;
    /*
    if (argc == 0 || !SYMBOL_P(argv[0])) {
      rb_raise(error_c.rb_eArgError, "no id given");
    }
    */

    // stack_check();

    id = SYM2ID(argv[0]);

    if (last_call_status & Node.NOEX_PRIVATE) {
      format = "private method '%s' called for %s";
    } else if (last_call_status & Node.NOEX_PROTECTED) {
      format = "protected method '%s' called for %s";
    }
    if (!format) {
      format = "undefined method '%s' for %s";
    }

    /*
    var n:int = 0;
    var args:Array = new Array(3);
    args[n++] = rb_funcall(rb_const_get(exc, parse_y.rb_intern("message")), "!".charCodeAt(), 3, rb_str_new2(format), obj, argv[0]);
    args[n++] = argv[0];
    if (exc == error_c.rb_eNoMethodError) {
      //args[n++] = rb_ary_new4(argc - 1, argv + 1);
    }
    exc = RClass(rb_class_new_instance(n, args, exc));
    */

    th.cfp = th.cfp_stack.pop();
    rb_exc_raise(exc);

    // will not be reached
    return Qnil;
  }

  public function rb_exc_raise(mesg:Value):void {
    throw new RTag(RTag.TAG_RAISE, mesg);
  }

  // object.c:1477
  public function rb_class_new_instance(argc:int, argv:Array, klass:RClass):Value {
    var obj:Value;

    obj = rb_obj_alloc(klass);
    rb_obj_call_init(obj, argc, argv);

    return obj;
  }

  public function idInitialize():uint {
    return (Id.tInitialize << Id.ID_SCOPE_SHIFT) | Id.ID_LOCAL;
  }

  // eval.c:856
  public function rb_obj_call_init(obj:Value, argc:int, argv:Array):void {
    // PASS_PASSED_BLOCK();
    rb_funcall2(obj, idInitialize(), argc, argv);
  }

  // vm_eval.c:354
  public function method_missing(obj:Value, id:int, argc:int, argv:Array, call_status:int):Value {
    var nargv:Array;

    GET_THREAD().method_missing_reason = call_status;

    if (id == missing) {
      rb_method_missing(argc, argv, obj);
    } else if (id == ID_ALLOCATOR) {
      rb_raise(error_c.rb_eTypeError, "allocator undefined for "+rb_class2name(RClass(obj)));
    }

    nargv = new Array(argc+1);
    nargv[0] = ID2SYM(id);
    for (var i:int = 0; i < argv.length; i++) {
      nargv[i+1] = argv[i];
    }

    return rb_funcall2(obj, missing, argc + 1, nargv);
  }

  // vm_eval.c:410
  public function rb_funcall2(recv:Value, mid:int, argc:int, argv:Array):Value {
    return rb_call(CLASS_OF(recv), recv, mid, argc, argv, Node.CALL_PUBLIC);
  }

  // vm_eval.c:190
  public function rb_call0(klass:RClass, recv:Value, mid:int, argc:int, argv:Array, scope:int, self:Value):Value {
    var body:Node;
    var method:Node;
    var noex:int;
    var id:int = mid;
    var th:RbThread = GET_THREAD();

    // Check method cache

    var idp:ByRef = new ByRef();
    method = rb_get_method_body(klass, id, idp);
    if (method) {
      noex = method.nd_noex();
      klass = method.nd_clss();
      body = method.nd_body();
      id = idp.v;
    } else {
      if (scope == 3) {
        return method_missing(recv, mid, argc, argv, Node.NOEX_SUPER);
      } else {
        return method_missing(recv, mid, argc, argv, scope == 2 ? Node.NOEX_VCALL : 0);
      }
    }

    // Various error condition checks

    return vm_call0(th, klass, recv, mid, id, argc, argv, body, noex & Node.NOEX_NOSUPER);
  }

  public function rb_call(klass:RClass, recv:Value, mid:int, argc:int, argv:Array, scope:int):Value {
    return rb_call0(klass, recv, mid, argc, argv, scope, Qundef);
  }

  public function rb_funcall(recv:Value, mid:int, n:int, ...argv):Value {
    return rb_call(CLASS_OF(recv), recv, mid, n, argv, Node.CALL_FCALL);
  }

  public function rb_class_inherited(super_class:RClass, klass:RClass):Value {
    var inherited:int;
    if (!super_class) {
      super_class = rb_cObject;
    }
    inherited = parse_y.rb_intern("inherited");
    return rb_funcall(super_class, inherited, 1, klass);
  }

  protected function rb_obj_dummy(...argv):Value {
    return Qnil;
  }

  // string.c
  public function
  rb_obj_as_string(obj:Value):RString
  {
    var val:Value;

    if (obj.get_type() == Value.T_STRING) {
      return RString(obj);
    }
    val = rb_funcall(obj, id_to_s, 0);
    if (val.get_type() != Value.T_STRING) {
      return rb_any_to_s(obj);
    }
    // OBJ_TAINTED
    return RString(val);
  }

  // object.c:299
  public function
  rb_any_to_s(obj:Value):RString
  {
    var cname:String = rb_obj_classname(obj);
    var str:RString;

    str = rb_str_new2("#<"+cname+":"+obj+">");
    // OBJ_INFECT(str, obj);

    return str;
  }


  public function bc_defineclass(stack:Array, id:int, class_iseq:Function, define_type:uint):void
  {
    var klass:RClass;
    var super_class:RClass = stack.pop();
    var cbase:RClass = stack.pop();

    switch (define_type) {
    case 0:
      // typical class definition
      if (super_class == Qnil) {
        super_class = rb_cObject;
      }

      // vm_check_if_namespace(cbase);

      if (rb_const_defined_at(cbase, id)) {
        var tmpValue:Value = rb_const_get_at(cbase, id);
        if (!tmpValue.is_class()) {
          rb_raise(error_c.rb_eTypeError, parse_y.rb_id2name(id)+" is not a class");
        }
        klass = RClass(tmpValue);

        if (super_class != rb_cObject) {
          var tmp:RClass = rb_class_real(klass.super_class);
          if (tmp != super_class) {
            rb_raise(error_c.rb_eTypeError, "superclass mismatch for class " + parse_y.rb_id2name(id));
          }
        }
      } else {
        // Create new class
        klass = rb_define_class_id(id, super_class);
        rb_set_class_path(klass, cbase, parse_y.rb_id2name(id));
        rb_const_set(cbase, id, klass);
        rb_class_inherited(super_class, klass);
      }
      break;
    case 1:
      // create singleton class
      break;
    case 2:
      // create module
      break;
    }
  }

  public function bc_leave(th:RbThread, cfp:RbControlFrame):void {
    if (cfp.sp != cfp.bp) {
      rb_bug("Stack consistency error (sp: "+cfp.sp+", bp: " +cfp.bp +")");
    }
    // RUBY_VM_CHECK_INTS();
    vm_pop_frame(th);
    // RESTORE_REGS();
  }

  public function RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp:RbControlFrame):RbBlock {
    return cfp;
  }

  public function caller_setup_args(th:RbThread, cfp:RbControlFrame, flag:uint, argc:int,
                                    blockiseq:Value, block:ByRef):int
  {
    var blockptr:RbBlock;

    if (block) {
      if (false) { //flag & RbVm.VM_CALL_ARGS_BLOCKARG_BIT) {
        // Handle dispatching to a proc
        /*
        var po:RbProc;
        var proc:Value;

        proc = cfp.sp.pop();

        if (proc != Qnil) {
          if (!rb_obj_is_proc(proc)) {

          }
        }
        */
      } else if (blockiseq) {
        blockptr = RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp);
        blockptr.block_iseq = blockiseq;
        blockptr.proc = null;
        block.v = blockptr;
      }
    }

    // handle splat args
    // if (flag & RbVm.VM_CALL_ARGS_SPLAT_BIT) {
    // }

    return argc;
  }

  public function TOPN(sp:Array, n:int):Value {
    return sp[sp.length-n-1];
  }

  public function rb_method_node(klass:RClass, id:int):Node {
    // check method cache
    return rb_get_method_body(klass, id, null);
  }

  public function vm_method_search(id:int, klass:RClass, ic:Value):Node {
    var mn:Node;

    // check inline method cache

    mn = rb_method_node(klass, id);

    return mn;
  }

  public function bc_send(th:RbThread, cfp:RbControlFrame, op_id:int, op_argc:int, blockiseq:Value, op_flag:int, ic:Value):void {
    var mn:Node;
    var recv:Value;
    var klass:RClass;
    var blockptr:ByRef = new ByRef();

    var val:Value;

    var num:int = caller_setup_args(th, cfp, op_flag, op_argc, blockiseq, blockptr);

    var flag:int = op_flag;
    var id:int = op_id;

    recv = (flag & RbVm.VM_CALL_FCALL_BIT) ? cfp.self : TOPN(cfp.sp, num);
    klass = CLASS_OF(recv);
    mn = vm_method_search(id, klass, ic);

    // send/funcall optimization

    //CALL_METHOD(num, blockptr, flag, id, mn, recv, klass);
    var v:Value = vm_call_method(th, cfp, num, blockptr.v, flag, id, mn, recv, klass);
    if (v == Qundef) {
      // This is already handled, perhaps, so just continue?
      // RESTORE_REGS();
      // NEXT_INSN();
    } else {
      val = v;
      cfp.sp.push(val);
    }


  }


}
}

