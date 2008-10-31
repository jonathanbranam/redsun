package ruby.internals
{
public class Object_c
{
  public var rc:RubyCore;

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


  protected function
  boot_defclass(name:String, super_class:RClass):RClass
  {
    var obj:RClass = rc.class_c.rb_class_boot(super_class);
    var id:int = rc.parse_y.rb_intern(name);
    rc.variable_c.rb_name_class(obj, id);
    rc.variable_c.rb_class_tbl[id] = obj;
    rc.variable_c.rb_const_set((rb_cObject ? rc.object_c.rb_cObject : obj), id, obj);
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
    rc.object_c.rb_cObject = boot_defclass("Object", rb_cBasicObject);
    rb_cModule = boot_defclass("Module", rc.object_c.rb_cObject);
    rb_cClass = boot_defclass("Class", rb_cModule);

    var metaclass:RClass;
    metaclass = rc.class_c.rb_make_metaclass(rb_cBasicObject, rb_cClass);
    metaclass = rc.class_c.rb_make_metaclass(rb_cObject, metaclass);
    metaclass = rc.class_c.rb_make_metaclass(rb_cModule, metaclass);
    metaclass = rc.class_c.rb_make_metaclass(rb_cClass, metaclass);

    rc.class_c.rb_define_private_method(rb_cBasicObject, "initialize", rb_obj_dummy, 0);
    rc.vm_method_c.rb_define_alloc_func(rb_cBasicObject, rb_class_allocate_instance);
    rc.class_c.rb_define_method(rb_cBasicObject, "==", rb_obj_equal, 1);
    rc.class_c.rb_define_method(rb_cBasicObject, "equal?", rb_obj_equal, 1);
    rc.class_c.rb_define_method(rb_cBasicObject, "!", rb_obj_not, 0);

    rc.class_c.rb_define_private_method(rb_cBasicObject, "singleton_method_added", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cBasicObject, "singleton_method_removed", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cBasicObject, "singleton_method_undefined", rb_obj_dummy, 1);

    //rc.class_c.rb_define_method(rb_cClass, "allocate", rb_obj_alloc, 0);

    rb_mKernel = rc.class_c.rb_define_module("Kernel");
    rc.class_c.rb_include_module(rb_cObject, rb_mKernel);
    rc.class_c.rb_define_private_method(rb_cClass, "inherited", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cModule, "included", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cModule, "extended", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cModule, "method_added", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cModule, "method_removed", rb_obj_dummy, 1);
    rc.class_c.rb_define_private_method(rb_cModule, "method_undefined", rb_obj_dummy, 1);

    rc.class_c.rb_define_method(rb_mKernel, "to_s", rb_any_to_s, 0);

    // Lots of kernel methods

    rb_cNilClass = rc.class_c.rb_define_class("NilClass", rc.object_c.rb_cObject);
    // nilclass methods
    rc.variable_c.rb_define_global_const("NIL", rc.Qnil);

    // Lots of module methods
    // Lots of class methods
    rc.class_c.rb_define_method(rb_cClass, "allocate", rb_obj_alloc, 0);
    rc.class_c.rb_define_method(rb_cClass, "new", rb_class_new_instance, -1);

    rc.class_c.rb_define_private_method(rb_cModule, "attr", rb_mod_attr, -1);
    rc.class_c.rb_define_private_method(rb_cModule, "attr_reader", rb_mod_attr_reader, -1);
    rc.class_c.rb_define_private_method(rb_cModule, "attr_writer", rb_mod_attr_writer, -1);
    rc.class_c.rb_define_private_method(rb_cModule, "attr_accessor", rb_mod_attr_accessor, -1);


    rb_cData = rc.class_c.rb_define_class("Data", rc.object_c.rb_cObject);
    // undef alloc func

    rb_cTrueClass = rc.class_c.rb_define_class("TrueClass", rc.object_c.rb_cObject);
    // setup trueclass
    rc.variable_c.rb_define_global_const("TRUE", rc.Qtrue);

    rb_cFalseClass = rc.class_c.rb_define_class("FalseClass", rc.object_c.rb_cObject);
    // setup falseclass
    rc.variable_c.rb_define_global_const("FALSE", rc.Qtrue);

    id_eq = rc.parse_y.rb_intern("==");
    id_eql = rc.parse_y.rb_intern("eql?");
    id_match = rc.parse_y.rb_intern("=~");
    id_inspect = rc.parse_y.rb_intern("inspect");
    id_init_copy = rc.parse_y.rb_intern("initialize_copy");

    rc.string_c.id_to_s = rc.parse_y.rb_intern("to_s");

  }

  public function
  rb_obj_class(obj:Value):RClass
  {
    return rb_class_real(rc.CLASS_OF(obj));
  }

  // object.c:299
  public function
  rb_any_to_s(obj:Value):RString
  {
    var cname:String = rc.variable_c.rb_obj_classname(obj);
    var str:RString;

    str = rc.string_c.rb_str_new2("#<"+cname+":"+obj+">");
    // OBJ_INFECT(str, obj);

    return str;
  }

  // object.c
  public function
  rb_inspect(val:Value):RString
  {
    var str:RString = new RString(rc.string_c.rb_cString);
    str.string = "rb_inspect results for "+val;
    return str;
  }

  protected function
  rb_obj_dummy(...argv):Value
  {
    return rc.Qnil;
  }

  // object.c
  public function
  rb_class_new(super_class:RClass):RClass
  {
    // Check_Type(super_class, T_CLASS);
    // rb_check_inheritable(super_class);
    if (super_class == rb_cClass) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't make subclass of Class");
    }
    return rc.class_c.rb_class_boot(super_class);
  }

  // object.c:1477
  public function
  rb_class_new_instance(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var obj:Value;

    obj = rb_obj_alloc(klass);
    rc.eval_c.rb_obj_call_init(obj, argc, argv);

    return obj;
  }

  public function
  rb_obj_equal(obj1:Value, obj2:Value):Value
  {
    if (obj1 == obj2) {
      return rc.Qtrue;
    } else {
      return rc.Qfalse;
    }
  }

  public function
  rb_obj_not(obj:Value):Value
  {
    return rc.RTEST(obj) ? rc.Qfalse : rc.Qtrue;
  }

  public function
  rb_obj_alloc(klass:RClass):Value
  {
    var obj:Value;

    if (klass.super_class == null && klass != rb_cBasicObject) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't instantiate uninitialized class");
    }
    if (klass.is_singleton()) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't create instance of singleton class");
    }
    obj = rc.vm_eval_c.rb_funcall(klass, rc.ID_ALLOCATOR, 0, null);
    if (rb_obj_class(obj) != rb_class_real(klass)) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "wrong instance allocation");
    }

    return obj;
  }


  // object.c:1964
  public function
  convert_type(val:Value, tname:String, method:String, raise:Boolean):Value
  {
    var m:int;

    m = rc.parse_y.rb_intern(method);
    if (!rc.vm_method_c.rb_respond_to(val, m)) {
      if (raise) {
        rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't convert "+
                  (rc.NIL_P(val) ? "nil " : val == rc.Qtrue ? "true" : val == rc.Qfalse ? "false" : rc.variable_c.rb_obj_classname(val)) +
                  " into " + tname);
      } else {
        return rc.Qnil;
      }
    }
    return rc.vm_eval_c.rb_funcall(val, m, 0);
  }

  // object.c:1986
  public function
  rb_convert_type(val:Value, type:int, tname:String, method:String):Value
  {
    var v:Value;

    if (val.get_type() == type) {
      return val;
    }
    v = convert_type(val, tname, method, true);
    if (v.get_type() != type) {
      var cname:String = rc.variable_c.rb_obj_classname(val);
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rc.variable_c.rb_obj_classname(v));
    }
    return v;
  }

  // object.c:2001
  public function
  rb_check_convert_type(val:Value, type:int, tname:String, method:String):Value
  {
    var v:Value;

    if (val.get_type() == type && type != Value.T_DATA) {
      return val;
    }
    v = convert_type(val, tname, method, false);
    if (rc.NIL_P(v)) {
      return rc.Qnil;
    }
    if (v.get_type() != type) {
      var cname:String = rc.variable_c.rb_obj_classname(val);
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rc.variable_c.rb_obj_classname(v));
    }
    return v;
  }

  // object.c:1457
  public function
  rb_class_allocate_instance(klass:RClass):RObject
  {
    var obj:RObject = new RObject(klass);
    obj.flags = Value.T_OBJECT;
    return obj;
  }

  // object.c:1535
  public function
  rb_mod_attr_reader(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var i:int;

    for (i = 0; i < argc; i++) {
      rc.vm_method_c.rb_attr(klass, rc.string_c.rb_to_id(argv.get_at(i)), true, false, true);
    }

    return rc.Qnil;
  }

  // object.c:1546
  public function
  rb_mod_attr(argc:int, argv:StackPointer, klass:RClass):Value
  {
    if (argc == 2 && (argv.get_at(1) == rc.Qtrue || argv.get_at(1) == rc.Qfalse)) {
      rc.error_c.rb_warning("optional boolean argument is obsoleted");
      rc.vm_method_c.rb_attr(klass, rc.string_c.rb_to_id(argv.get_at(0)), true, rc.RTEST(argv.get_at(1)), true);
      return rc.Qnil;
    }
    return rb_mod_attr_reader(argc, argv, klass);
  }

  // object.c:1565
  public function
  rb_mod_attr_writer(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var i:int;

    for (i = 0; i < argc; i++) {
      rc.vm_method_c.rb_attr(klass, rc.string_c.rb_to_id(argv.get_at(i)), false, true, true);
    }

    return rc.Qnil;
  }

  // object:1591
  public function
  rb_mod_attr_accessor(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var i:int;

    for (i = 0; i < argc; i++) {
      rc.vm_method_c.rb_attr(klass, rc.string_c.rb_to_id(argv.get_at(i)), true, true, true);
    }

    return rc.Qnil;
  }




}
}
