package ruby.internals
{
public class Object_c
{
  protected var rc:RubyCore;

  public var variable_c:Variable_c;
  public var class_c:Class_c;
  public var parse_y:Parse_y;

  public var rb_cBasicObject:RClass;
  public var rb_mKernel:RClass
  public var rb_cObject:RClass;
  public var rb_cModule:RClass;
  public var rb_cClass:RClass;
  public var rb_cData:RClass;

  public var rb_cNilClass:RClass;
  public var rb_cTrueClass:RClass;
  public var rb_cFalseClass:RClass;

  // various files static - object.c:35
  public var id_eq:int, id_eql:int, id_match:int, id_inspect:int, id_init_copy:int;


  public function Object_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  protected function
  boot_defclass(name:String, super_class:RClass):RClass
  {
    var obj:RClass = class_c.rb_class_boot(super_class);
    var id:int = parse_y.rb_intern(name);
    variable_c.rb_name_class(obj, id);
    variable_c.rb_class_tbl[id] = obj;
    variable_c.rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
    return obj;
  }


  public function
  rb_class_real(cl:RClass):RClass
  {
    if (!cl) {
      return null;
    }
    while (cl.is_singleton() || cl.is_include_class()) {
      cl = RClass(cl).super_class;
    }
    return cl;
  }


  public function
  Init_Object():void
  {
    rb_cBasicObject = boot_defclass("BasicObject", null);
    rb_cObject = boot_defclass("Object", rb_cBasicObject);
    rb_cModule = boot_defclass("Module", rb_cObject);
    rb_cClass = boot_defclass("Class", rb_cModule);

    var metaclass:RClass;
    metaclass = class_c.rb_make_metaclass(rb_cBasicObject, rb_cClass);
    metaclass = class_c.rb_make_metaclass(rb_cObject, metaclass);
    metaclass = class_c.rb_make_metaclass(rb_cModule, metaclass);
    metaclass = class_c.rb_make_metaclass(rb_cClass, metaclass);

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

    rb_cNilClass = class_c.rb_define_class("NilClass", rb_cObject);
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

  public function rb_obj_class(obj:Value):RClass {
    return rb_class_real(rc.CLASS_OF(obj));
  }

  // object.c:299
  public function
  rb_any_to_s(obj:Value):RString
  {
    var cname:String = variable_c.rb_obj_classname(obj);
    var str:RString;

    str = string_c.rb_str_new2("#<"+cname+":"+obj+">");
    // OBJ_INFECT(str, obj);

    return str;
  }


}
}
