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

  protected var autoload:String;
  protected var classpath:String;
  protected var tmp_classpath:String;

  public var rb_cBasicObject:RClass;
  public var rb_cObject:RClass;
  public var rb_cModule:RClass;
  public var rb_cClass:RClass;

  public static const ID_ALLOCATOR:String = "allocate";

  public function RubyCore()  {
  }

  public function run(docClass:DisplayObject, block:Function):void  {
    init();
    RGlobal.global.send_external(null, "const_set", "Document", docClass);
    RGlobal.global.send_external(null, "module_eval", block);
  }

  protected function Init_var_tables():void {
    rb_class_tbl = {};
    rb_global_tbl = {};
    autoload = rb_intern("__autoload__");
    classpath = rb_intern("__classpath__");
    tmp_classpath = rb_intern("__tmp_classpath__");
  }

  public function init():void  {
    Init_var_tables();
    Init_Object();
    //define_ruby_classes();
    //define_flash_classes();
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
    return obj.iv_tbl[id];
  }

  protected function rb_ivar_set(obj:RObject, id:String, val:*):void {
    if (obj is RClass) {
      obj.iv_tbl[id] = val;
    }

  }

  protected function rb_intern(str:String):String {
    return str;
  }

  protected function rb_iv_set(obj:RObject, name:String, val:*):void {
    rb_ivar_set(obj, rb_intern(name), val);
  }

  protected function rb_name_class(klass:RClass, id:String):void {
    rb_iv_set(klass, "__classid__", id);
  }

  protected function rb_const_set(obj:RObject, id:String, val:*):void {
    obj.iv_tbl[id] = val;
  }

  protected function boot_defclass(name:String, super_class:RClass):RClass {
    var obj:RClass = rb_class_boot(super_class);
    var id:String = rb_intern(name);
    rb_name_class(obj, id);
    rb_class_tbl[id] = obj;
    rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
    return obj;
  }

  protected function rb_singleton_class_attached(klass:RClass, obj:RObject):void {
    if (klass.is_singleton()) {
      var attached:String = rb_intern("__attached__");
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

  protected function rb_add_method(klass:RClass, mid:String, node:Node, noex:uint):void {
    if (!klass) {
      klass = rb_cObject;
    }
    if (!klass.is_singleton() &&
      node && node.nd_type() != Node.NODE_ZSUPER &&
      (mid == rb_intern("initialize") || mid == rb_intern("initialize_copy")))
    {
      noex |= Node.NOEX_PRIVATE;
    } else if (klass.is_singleton() && node
      && node.nd_type() == Node.NODE_CFUNC && mid == rb_intern("allocate")) {
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
    rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }

  protected function rb_define_protected_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PROTECTED);
  }

  protected function rb_define_private_method(klass:RClass, name:String, func:Function, argc:int):void {
    rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PRIVATE);
  }

  protected function ivar_get(obj:RObject, id:String, warn:Boolean):* {
    var val:*;

    switch (obj.type()) {
      case Value.T_OBJECT:
        val = obj.iv_tbl[id];
        if (val != undefined && val != Qundef) {
          return val;
        }
        break;
      case Value.T_CLASS:
      case Value.T_MODULE:
        val = obj.iv_tbl[id];
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

  protected function rb_ivar_get(obj:RObject, id:String):* {
   return ivar_get(obj, id, true);
  }

  protected function rb_iv_get(obj:RObject, name:String):* {
    return rb_ivar_get(obj, rb_intern(name));
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

  protected function rb_obj_dummy():Value {
    return Qnil;
  }

}
}

