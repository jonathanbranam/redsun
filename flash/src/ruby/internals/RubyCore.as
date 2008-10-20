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

  // vm_method.c:12
  public var __send__:int, object_id:int;
  public var removed:int, singleton_removed:int, undefined_:int, singleton_undefined:int;
  public var eqq:int, each_:int, aref:int, aset:int, match:int, missing:int;
  public var added:int, singleton_added:int;

  // Modules
  public var parse_y:Parse_y;
  public var string_c:String_c;
  public var error_c:Error_c;
  public var vm_c:Vm_c;
  public var iseq_c:Iseq_c;
  public var io_c:IO_c;
  public var vm_insnhelper_c:Vm_insnhelper_c;
  public var class_c:Class_c;
  public var object_c:Object_c;
  public var variable_c:Variable_c;

  public function RubyCore()  {
  }

  public function run(docClass:DisplayObject, block:Function):void  {
    ruby_init();
    //RGlobal.global.send_external(null, "const_set", "Document", docClass);
    //RGlobal.global.send_external(null, "module_eval", block);
  }

  public function ruby_init():void {
    parse_y = new Parse_y(this);
    string_c = new String_c(this);
    error_c = new Error_c(this);
    vm_c = new Vm_c(this);
    iseq_c = new Iseq_c(this);
    io_c = new IO_c(this);
    vm_insnhelper_c = new Vm_insnhelper_c(this);
    class_c = new Class_c(this);
    object_c = new Object_c(this);
    variable_c = new Variable_c(this);

    parse_y.string_c = string_c;
    string_c.parse_y = parse_y;
    string_c.error_c = error_c;
    iseq_c.vm_c = vm_c;

    vm_c.iseq_c = iseq_c;
    vm_c.vm_insnhelper_c = vm_insnhelper_c;

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
      error_c.rb_raise(error_c.rb_eTypeError, "Not a toplevel InstructionSequence");
    }

    rb_vm_set_finish_env(th);

    vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_TOP, th.top_self, null, iseq.iseq_fn,
                  th.cfp.sp, null, iseq.local_size);
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

    var frame:RubyFrame = new RubyFrame(this, th, th.cfp);

    ret = th.cfp.pc.call(this, frame);

    if (th.cfp.VM_FRAME_TYPE() != RbVm.VM_FRAME_MAGIC_FINISH) {
      error_c.rb_bug("cfp consistency error");
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

  public function main(n:Value):void  {
    //ruby_set_debug_option(getenv("RUBY_DEBUG"));
    //ruby_sysinit(&argc, &argv);
    //RUBY_INIT_STACK;
    ruby_init();
    ruby_run_node(n);
  }

  public function rb_call_inits():void {
    ID_ALLOCATOR = parse_y.rb_intern("allocate");

    //Init_RandomSeed();
    //Init_sym();
    variable_c.Init_var_tables();
    object_c.Init_Object();
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

  public function convert_type(val:Value, tname:String, method:String, raise:Boolean):Value {
    var m:int;

    m = parse_y.rb_intern(method);
    if (!rb_respond_to(val, m)) {
      if (raise) {
        error_c.rb_raise(error_c.rb_eTypeError, "can't convert "+
                  (NIL_P(val) ? "nil " : val == Qtrue ? "true" : val == Qfalse ? "false" : variable_c.rb_obj_classname(val)) +
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
      var cname:String = variable_c.rb_obj_classname(val);
      error_c.rb_raise(error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               variable_c.rb_obj_classname(v));
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
      error_c.rb_raise(error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
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
      error_c.rb_raise(error_c.rb_eArgError, "no method name given");
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

    if (klass.super_class == null && klass != object_c.rb_cBasicObject) {
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

  protected function define_flash_classes():void {
    /*
    define_class("Flash",
      RGlobal.global.send_external(null, "const_get", "Object"),
      function ():* {
      });
    */
  }

  // vm_method.c:104
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

  public function rb_safe_level():int {
    return 0;
    //return GET_THREAD()->safe_level;
  }

  // vm_method.c:192
  public function rb_define_alloc_func(klass:RClass, func:Function):void {
    // Check_Type(klass, T_CLASS);
    rb_add_method(class_c.rb_singleton_class(klass), ID_ALLOCATOR, NEW_CFUNC(func, 0), Node.NOEX_PRIVATE);
  }

  public function rb_class_allocate_instance(klass:RClass):RObject {
    var obj:RObject = new RObject(klass);
    obj.flags = Value.T_OBJECT;
    return obj;
  }

  public function rb_obj_equal(obj1:Value, obj2:Value):Value {
    if (obj1 == obj2) {
      return Qtrue;
    } else {
      return Qfalse;
    }
  }

  public function RTEST(v:Value):Boolean {
    //  (((VALUE)(v) & ~Qnil) != 0)
    return v != null && v != Qnil;
  }

  public function NIL_P(v:Value):Boolean {
    return v == Qnil;
  }

  public function rb_obj_not(obj:Value):Value {
    return RTEST(obj) ? Qfalse : Qtrue;
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

  public function rb_class_of(obj:Value):RClass {
    // Test for immediate objects and special values
    if (obj == Qnil)   return object_c.rb_cNilClass;
    if (obj == Qtrue)  return object_c.rb_cTrueClass;
    if (obj == Qfalse) return object_c.rb_cFalseClass;
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
      var iseqval:Value = body.nd_body;
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

        val = call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);

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

        node = mn.nd_body;

        switch (node.nd_type()) {
        case Node.RUBY_VM_METHOD_NODE: {
          vm_setup_method(th, cfp, num, blockptr, flag, node.nd_body, recv, klass);
          return Qundef;
        }
        case Node.NODE_CFUNC: {
          val = vm_call_cfunc(th, cfp, num, id, recv, mn.nd_clss, flag, node, blockptr);
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

      val = call_cfunc(mn.nd_cfnc, recv, mn.nd_argc, num, argv);

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
    if (!fbody || fbody.nd_body == null) {
      // store empty info in cache
      return null;
    }

    method = fbody.nd_body;

    if (ruby_running()) {
      // Store in cache;
      body = method;
    } else {
      body = method;
    }

    if (idp) {
      idp.v = fbody.nd_oid;
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
      noex = method.nd_noex;
      klass = method.nd_clss;
      body = method.nd_body;
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

  protected function rb_obj_dummy(...argv):Value {
    return Qnil;
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

  public function iseqval_from_func(func:Function):Value {
    var iseq:RbISeq = new RbISeq();
    iseq.type = RbVm.ISEQ_TYPE_TOP;
    iseq.iseq_fn = func;
    return Data_Wrap_Struct(iseq_c.rb_cISeq, iseq, null, null);
  }


}
}

