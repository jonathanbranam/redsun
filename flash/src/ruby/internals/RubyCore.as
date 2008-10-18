package ruby.internals
{
import flash.display.DisplayObject;

import ruby.RObject;


/**
 * Class for core ruby methods.
 */
public class RubyCore
{
  protected var ruby_running:Boolean = true;

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

  public var rb_eTypeError:RClass;

  public var ID_ALLOCATOR:int;

  public var ruby_current_thread:RbThread;
  public var ruby_current_vm:RbVm;

  // Modules
  public var rb_id:Id;

  public function RubyCore()  {
  }

  public function run(docClass:DisplayObject, block:Function):void  {
    ruby_init();
    RGlobal.global.send_external(null, "const_set", "Document", docClass);
    RGlobal.global.send_external(null, "module_eval", block);
  }

  public function ruby_run_node(n:Node):void {
    // Init_stack(n);
    ruby_cleanup(ruby_exec_node(n, null));
  }

  public function ruby_cleanup(ex:int):int {
    // cleanup, GC, stop threads, error hanlding
    return ex;
  }

  public function ruby_exec_node(n:Node, file:String):int {
    rb_iseq_eval(n);
    return 0;
  }

  public function GET_THREAD():RbThread {
    return ruby_current_thread;
  }

  public function vm_set_top_stack(th:RbThread, iseqval:Node):void {
    var iseq:RbISeq;

    iseq = GetISeqPtr(iseqval);

    if (iseq.type != RbVm.ISEQ_TYPE_TOP) {
      rb_raise(rb_eTypeError, "Not a toplevel InstructionSequence");
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
    var id:int = rb_id.rb_intern(name);

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

  public function rb_iseq_eval(iseqval:Node):Value {
    var th:RbThread = GET_THREAD();
    vm_set_top_stack(th, iseqval);
    //rb_define_global_const("TOPLEVEL_BINDING", rb_binding_new());
    return vm_eval_body(th);
  }

  public function vm_eval_body(th:RbThread):Value {
    var result:Value;
    var initial:Value;

    result = vm_eval(th, initial);

    // Exception handling.

    // if state == TAG_RETRY
    // search catch_table for RETRY entry
    // etc.

    return result;
  }

  public function vm_eval(th:RbThread, initial:Value):Value {
    var ret:Value;

    ret = th.cfp.pc.call(this, th, th.cfp);

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

  public function bc_leave(th:RbThread, cfp:RbControlFrame):void {
    if (cfp.sp != cfp.bp) {
      rb_bug("Stack consistency error (sp: "+cfp.sp+", bp: " +cfp.bp +")");
    }
    // RUBY_VM_CHECK_INTS();
    vm_pop_frame(th);
    // RESTORE_REGS();
  }

  public function rb_bug(message:String):void {
    throw new Error("rb_bug: " + message);
  }

  protected function Init_var_tables():void {
    rb_class_tbl = {};
    rb_global_tbl = {};
    autoload = rb_id.rb_intern("__autoload__");
    classpath = rb_id.rb_intern("__classpath__");
    tmp_classpath = rb_id.rb_intern("__tmp_classpath__");
    ID_ALLOCATOR = rb_id.rb_intern("allocate");
  }

  public function main(n:Node):void  {
    //ruby_set_debug_option(getenv("RUBY_DEBUG"));
    //ruby_sysinit(&argc, &argv);
    //RUBY_INIT_STACK;
    ruby_init();
    ruby_run_node(n);
  }

  public function rb_call_inits():void {
    Init_var_tables();
    Init_Object();
    //define_ruby_classes();
    //define_flash_classes();

    rb_eTypeError = new RClass("TypeError", rb_cClass);
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
    rb_id = new Id();
    Qnil = new RNil();
    Qtrue = new RTrue();
    Qfalse = new RFalse();
    Qundef = new RUndef();


    //Init_stack(&state);
    Init_BareVM();
    Init_heap();
    rb_call_inits();
    ruby_prog_init();
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
    rb_ivar_set(obj, rb_id.rb_intern(name), val);
  }

  protected function rb_name_class(klass:RClass, id:int):void {
    rb_iv_set(klass, "__classid__", id);
  }

  protected function rb_const_set(obj:RObject, id:int, val:*):void {
    obj.iv_tbl[id] = val;
  }

  protected function boot_defclass(name:String, super_class:RClass):RClass {
    var obj:RClass = rb_class_boot(super_class);
    var id:int = rb_id.rb_intern(name);
    rb_name_class(obj, id);
    rb_class_tbl[id] = obj;
    rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
    return obj;
  }

  protected function rb_singleton_class_attached(klass:RClass, obj:RObject):void {
    if (klass.is_singleton()) {
      var attached:int = rb_id.rb_intern("__attached__");
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
      klass.flags |= RClass.FL_SINGLETON;
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
      (mid == rb_id.rb_intern("initialize") || mid == rb_id.rb_intern("initialize_copy")))
    {
      noex |= Node.NOEX_PRIVATE;
    } else if (klass.is_singleton() && node
      && node.nd_type() == Node.NODE_CFUNC && mid == rb_id.rb_intern("allocate")) {
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
    return (s << 8) | n | (ruby_running ? 0 : Node.NOEX_BASIC);
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

  protected function rb_define_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, rb_id.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }

  protected function rb_define_protected_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, rb_id.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PROTECTED);
  }

  protected function rb_define_private_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, rb_id.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PRIVATE);
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
    return rb_ivar_get(obj, rb_id.rb_intern(name));
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
    return v != Qnil;
  }

  public function NIL_P(v:Value):Boolean {
    return v == Qnil;
  }

  protected function rb_obj_not(obj:Value):Value {
    return RTEST(obj) ? Qfalse : Qtrue;
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

  public function SYM2ID(sym:Value):String {
    if (sym.get_type() == Value.T_STRING) {
      return RString(sym).string;
    } else {
      return "";
    }
  }

  public function rb_id2str(id:String):RString {
    return rb_str_new(id);
  }

  public function classname(klass:RClass):Value {
    var path:Value = Qnil;

    if (!klass) {
      klass = rb_cObject;
    }
    if (klass.iv_tbl[classpath] != undefined) {
      path = klass.iv_tbl[classpath];
      var classid:int = rb_id.rb_intern("__classid__");

      if (klass.iv_tbl[classid] == undefined) {
        return find_class_path(klass);
      }
      path = rb_str_dup(rb_id2str(SYM2ID(path)));
      // OBJ_FREEZE(path);
      klass.iv_tbl[classpath] = path;
      delete klass.iv_tbl[classid];

    }
    if (!path.is_string()) {
      rb_bug("class path is not set propertly");
    }
    return path;
  }

  public function rb_obj_class(obj:RBasic):RClass {
    return rb_class_real(obj.klass);
  }

  public function rb_class_name(klass:RClass):Value {
    return rb_class_path(rb_class_real(klass));
  }

  public function rb_class2name(klass:RClass):String {
    return RString(rb_class_name(klass)).string;
  }

  public function rb_class_path(klass:RClass):Value {
    var path:Value = classname(klass);

    if (NIL_P(path)) {
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
      rb_raise(rb_eTypeError, "can't make subclass of Class");
    }
    return rb_class_boot(super_class);
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

  public function rb_class_of(v:Value):RClass {
    // Test for immediate objects and special values
    return RBasic(v).klass;
  }

  public function CLASS_OF(v:Value):RClass {
    return rb_class_of(v);
  }

  public function GetISeqPtr(obj:Value):RbISeq {
    return RbISeq(obj);
  }

  public function vm_setup_method(th:RbThread, cfp:RbControlFrame, argc:int, blockptr:RbBlock,
      flag:uint, iseqval:Value, recv:Value, klass:RClass):void
  {
    // various checks
    var iseq:RbISeq;
    var sp:Array = cfp.sp; // cfp->sp - argc

    iseq = GetISeqPtr(iseqval);

    vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_METHOD, recv, blockptr, iseq.iseq_fn, sp, null, 0);
  }

  public function rb_vm_set_finish_env(th:RbThread):Value {
    vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_FINISH, Qnil, th.cfp.lfp[0], null, th.cfp.sp, null, 1);
    th.cfp.pc = function (th:RbThread, cfp:RbControlFrame):Value { this.finish(); return this.Qnil; };
    return Qtrue;
  }

  public function vm_call0(th:RbThread, klass:RClass, recv:Value, id:int, oid:int, argc:int, argv:Array, body:Node, nosuper:int):Value {
    var val:Value;
    var blockptr:RbBlock;

    if (th.passed_block) {
      blockptr = th.passed_block;
      th.passed_block = null;
    }

    switch (body.nd_type()) {
    case Node.RUBY_VM_METHOD_NODE:{
      var reg_cfp:RbControlFrame;
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
    return Qnil;
  }

  public function ruby_node_name(type:uint):String {
    return "Node :" + type;
  }

  public function search_method(klass:RClass, id:int, klassp:RClass):Node {
    var body:Node = null;

    if (!klass) {
      return null;
    }

    while (body = klass.m_tbl[id]) {
      klass = klass.super_class;
      if (klass == null) {
        return null;
      }
    }

    return body;
  }

  public function rb_get_method_body(klass:RClass, id:int /*, ID *idp*/):Node {
    var fbody:Node;
    var body:Node;
    var method:Node;

    fbody = search_method(klass, id, null);
    if (!fbody || fbody.nd_body() == null) {
      // store empty info in cache
      return null;
    }

    method = fbody.nd_body();

    if (ruby_running) {
      // Store in cache;
    } else {
      body = method;
    }

    /*
    if (idp) {
      *idp = fbody.nd_oid();
    }
    */

    return body;
  }

  public function rb_call0(klass:RClass, recv:Value, mid:int, argc:int, argv:Array, scope:int, self:Value):Value {
    var body:Node;
    var method:Node;
    var noex:int;
    var id:int = mid;
    var th:RbThread = GET_THREAD();

    // Check method cache

    method = rb_get_method_body(klass, id);
    if (method) {
      noex = method.nd_noex();
      klass = method.nd_clss();
      body = method.nd_body();
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
    inherited = rb_id.rb_intern("inherited");
    return rb_funcall(super_class, inherited, 1, klass);
  }

  public function defineclass(stack:Array, id:int, class_iseq:Function, define_type:uint):void
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
          rb_raise(rb_eTypeError, rb_id.rb_id2name(id)+" is not a class");
        }
        klass = RClass(tmpValue);

        if (super_class != rb_cObject) {
          var tmp:RClass = rb_class_real(klass.super_class);
          if (tmp != super_class) {
            rb_raise(rb_eTypeError, "superclass mismatch for class " + rb_id.rb_id2name(id));
          }
        }
      } else {
        // Create new class
        klass = rb_define_class_id(id, super_class);
        rb_set_class_path(klass, cbase, rb_id.rb_id2name(id));
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

  protected function rb_obj_dummy():Value {
    return Qnil;
  }

}
}

