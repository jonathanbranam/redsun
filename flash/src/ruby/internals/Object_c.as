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
    var obj:RClass = rb_class_boot(super_class);
    var id:int = rb_intern(name);
    rb_name_class(obj, id);
    rb_class_tbl[id] = obj;
    rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
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
    // Lots of class methods
    rb_define_method(rb_cClass, "allocate", rb_obj_alloc, 0);
    rb_define_method(rb_cClass, "new", rb_class_new_instance, -1);

    rb_cData = rb_define_class("Data", rb_cObject);
    // undef alloc func

    rb_cTrueClass = rb_define_class("TrueClass", rb_cObject);
    // setup trueclass
    rb_define_global_const("TRUE", Qtrue);

    rb_cFalseClass = rb_define_class("FalseClass", rb_cObject);
    // setup falseclass
    rb_define_global_const("FALSE", Qtrue);

    id_eq = rb_intern("==");
    id_eql = rb_intern("eql?");
    id_match = rb_intern("=~");
    id_inspect = rb_intern("inspect");
    id_init_copy = rb_intern("initialize_copy");

    id_to_s = rb_intern("to_s");

  }

  public function
  rb_obj_class(obj:Value):RClass
  {
    return rb_class_real(CLASS_OF(obj));
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

  // object.c
  public function
  rb_inspect(val:Value):RString
  {
    var str:RString = new RString(rb_cString);
    str.string = "rb_inspect results for "+val;
    return str;
  }

  protected function
  rb_obj_dummy(...argv):Value
  {
    return Qnil;
  }

  // object.c
  public function
  rb_class_new(super_class:RClass):RClass
  {
    // Check_Type(super_class, T_CLASS);
    // rb_check_inheritable(super_class);
    if (super_class == rb_cClass) {
      rb_raise(rb_eTypeError, "can't make subclass of Class");
    }
    return rb_class_boot(super_class);
  }

  // object.c:1477
  public function
  rb_class_new_instance(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var obj:Value;

    obj = rb_obj_alloc(klass);
    rb_obj_call_init(obj, argc, argv);

    return obj;
  }

  public function
  rb_obj_equal(obj1:Value, obj2:Value):Value
  {
    if (obj1 == obj2) {
      return Qtrue;
    } else {
      return Qfalse;
    }
  }

  public function
  rb_obj_not(obj:Value):Value
  {
    return RTEST(obj) ? Qfalse : Qtrue;
  }

  public function
  rb_obj_alloc(klass:RClass):Value
  {
    var obj:Value;

    if (klass.super_class == null && klass != rb_cBasicObject) {
      rb_raise(rb_eTypeError, "can't instantiate uninitialized class");
    }
    if (klass.is_singleton()) {
      rb_raise(rb_eTypeError, "can't create instance of singleton class");
    }
    obj = rb_funcall(klass, ID_ALLOCATOR, 0, null);
    if (rb_obj_class(obj) != rb_class_real(klass)) {
      rb_raise(rb_eTypeError, "wrong instance allocation");
    }

    return obj;
  }


  // object.c:1964
  public function
  convert_type(val:Value, tname:String, method:String, raise:Boolean):Value
  {
    var m:int;

    m = rb_intern(method);
    if (!rb_respond_to(val, m)) {
      if (raise) {
        rb_raise(rb_eTypeError, "can't convert "+
                  (NIL_P(val) ? "nil " : val == Qtrue ? "true" : val == Qfalse ? "false" : rb_obj_classname(val)) +
                  " into " + tname);
      } else {
        return Qnil;
      }
    }
    return rb_funcall(val, m, 0);
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
      var cname:String = rb_obj_classname(val);
      rb_raise(rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rb_obj_classname(v));
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
    if (NIL_P(v)) {
      return Qnil;
    }
    if (v.get_type() != type) {
      var cname:String = rb_obj_classname(val);
      rb_raise(rb_eTypeError, "can't convert "+cname+" to "+tname+" ("+cname+"#"+method+" gives "+
               rb_obj_classname(v));
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


