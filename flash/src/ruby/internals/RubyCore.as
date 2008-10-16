package ruby.internals
{
import flash.display.DisplayObject;

import ruby.RObject;


/**
 * Class for core ruby methods.
 */
public class RubyCore
{
  protected var rb_class_tbl:Object = {};
  public var rb_cBasicObject:RClass;
  public var rb_cObject:RClass;
  public var rb_cModule:RClass;
  public var rb_cClass:RClass;


  public function RubyCore()  {
  }

  public function run(docClass:DisplayObject, block:Function):void  {
    init();
    RGlobal.global.send_external(null, "const_set", "Document", docClass);
    RGlobal.global.send_external(null, "module_eval", block);
  }

  public function init():void  {
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
    if (klass.rbasic.flags & RClass.SINGLETON != 0) {
      var attached:String = rb_intern("__attached__");
      klass.iv_tbl[attached] = obj;
    }
  }

  public static const T_MASK:uint = 0x1f;
  public static const T_ICLASS:uint = 0x1d;

  protected function BUILTIN_TYPE(x:RObject):uint {
    return x.rbasic.flags & T_MASK;
  }

  protected function rb_class_real(cl:RClass):RClass {
    if (!cl) {
      return null;
    }
    while (cl.rbasic.flags & RClass.SINGLETON || BUILTIN_TYPE(cl) == T_ICLASS) {
      cl = RClass(cl).super_class;
    }
    return cl;
  }

  protected function rb_make_metaclass(obj:RObject, super_class:RClass):RClass {
    /*
    if (BUILTIN_TYPE(obj) == T_CLASS && FL_TEST(obj, FL_SINGLETON)) {
      return object.basic.klass = rb_cClass;
    } else {
    */
    var klass:RClass = rb_class_boot(super_class);
    klass.rbasic.flags |= RClass.SINGLETON;
    obj.rbasic.klass = klass;
    rb_singleton_class_attached(klass, obj);

    var metasuper:RClass = rb_class_real(super_class).klass;
    if (metasuper) {
      klass.rbasic.klass = metasuper;
    }
    return klass;
  }

  protected function Init_Object():void {
    rb_cBasicObject = boot_defclass("BasicObject", null);
    rb_cObject = boot_defclass("Object", rb_cBasicObject);
    rb_cModule = boot_defclass("Module", rb_cObject);
    rb_cClass = boot_defclass("Class", rb_cModule);

    var metaclass:RClass;
    metaclass = rb_make_metaclass(rb_cBasicObject, rb_cClass);
  }

}
}

