package ruby.internals
{

public class Class_c
{
  protected var rc:RubyCore;

  public var object_c:Object_c;
  public var parse_y:Parse_y;
  public var variable_c:Variable_c;
  public var error_c:Error_c;

  public function Class_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function
  rb_singleton_class_attached(klass:RClass, obj:RObject):void
  {
    if (klass.is_singleton()) {
      var attached:int = parse_y.rb_intern("__attached__");
      klass.iv_tbl[attached] = obj;
    }
  }

  public function
  rb_class_boot(super_class:RClass):RClass
  {
    var klass:RClass = new RClass(null, super_class, object_c.rb_cClass);
    // OBJ_INFECT(klass, super_class);
    return klass;
  }

  public function
  rb_make_metaclass(obj:RObject, super_class:RClass):RClass {
    if (obj.is_class() && RClass(obj).is_singleton()) {
      return obj.klass = object_c.rb_cClass;
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

      var metasuper:RClass = object_c.rb_class_real(super_class).klass;
      if (metasuper) {
        klass.klass = metasuper;
      }
      return klass;
    }
  }


  public function
  rb_singleton_class(obj:Value):RClass {
    // Special casing skipped
    trace("Skipping rb_singleton_class special casing");

    var klass:RClass;

    var oobj:RObject = RObject(obj);
    if (oobj.klass.is_singleton() && variable_c.rb_iv_get(oobj.klass, "__attached__") == obj) {
      klass = oobj.klass;
    } else {
      klass = rb_make_metaclass(oobj, oobj.klass);
    }

    // Taint, trust, frozen checks skipped
    trace("Skipping rb_singleton_class taint, trust, frozen checks");

    return klass;
  }

  public function
  rb_class_new(super_class:RClass):RClass
  {
    // Check_Type(super_class, T_CLASS);
    // rb_check_inheritable(super_class);
    if (super_class == object_c.rb_cClass) {
      error_c.rb_raise(error_c.rb_eTypeError, "can't make subclass of Class");
    }
    return rb_class_boot(super_class);
  }

  public function
  rb_define_class_id(id:int, super_class:RClass):RClass
  {
    var klass:RClass;

    if (!super_class) {
      super_class = object_c.rb_cObject;
    }

    klass = rb_class_new(super_class);
    rb_make_metaclass(klass, super_class.klass);

    return klass;
  }

  // class.c:234
  public function
  rb_define_class(name:String, super_class:RClass):RClass
  {
    var klass:RClass;
    var val:Value;
    var id:int;

    id = parse_y.rb_intern(name);
    if (variable_c.rb_const_defined(object_c.rb_cObject, id)) {
      val = variable_c.rb_const_get(object_c.rb_cObject, id);
      if (val.get_type() != Value.T_CLASS) {
        error_c.rb_raise(error_c.rb_eTypeError, name+" is not a class");
      }
      klass = RClass(val);
      if (rb_class_real(klass.super_class) != super_class) {
        error_c.rb_name_error(id, name+" is already defined");
      }
      return klass;
    }
    if (!super_class) {
      error_c.rb_warn("no super class for '"+name+"', Object assumed");
    }

    klass = rb_define_class_id(id, super_class);
    variable_c.rb_class_tbl[id] = klass;
    rb_name_class(klass, id);
    rb_const_set(object_c.rb_cObject, id, klass);
    rb_class_inherited(super_class, klass);

    return klass;
  }

  // class.c:263
  public function
  rb_define_class_under(outer:RClass, name:String, super_class:RClass):RClass
  {
    var klass:RClass;
    var id:int;

    id = parse_y.rb_intern(name);
    if (variable_c.rb_const_defined_at(outer, id)) {
      var val:Value = variable_c.rb_const_get_at(outer, id);
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

  public function
  rb_class_inherited(super_class:RClass, klass:RClass):Value
  {
    var inherited:int;
    if (!super_class) {
      super_class = object_c.rb_cObject;
    }
    inherited = parse_y.rb_intern("inherited");
    return rb_funcall(super_class, inherited, 1, klass);
  }

  // class.c:855
  public function
  rb_define_module_function(module:RClass, name:String, func:Function, argc:int):void
  {
    rb_define_private_method(module, name, func, argc);
    rb_define_singleton_method(module, name, func, argc);
  }

  // class.c:862
  public function
  rb_define_global_function(name:String, func:Function, argc:int):void
  {
    rb_define_module_function(rb_mKernel, name, func, argc);
  }

  // class.c:778
  public function
  rb_define_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }

  // class.c:784
  public function
  rb_define_protected_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PROTECTED);
  }

  // class.c:790
  public function
  rb_define_private_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rb_add_method(klass, parse_y.rb_intern(name), NEW_CFUNC(func, argc), Node.NOEX_PRIVATE);
  }


  // class.c:380
  public function
  rb_include_module(klass:RClass, module:RClass):void
  {
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
  protected function
  include_class_new(module:RClass, super_class:RClass):RClass
  {
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
  public function
  rb_define_module(name:String):RClass
  {
    var module:RClass;
    var id:int;
    var val:Value;

    id = parse_y.rb_intern(name);
    if (variable_c.rb_const_defined(object_c.rb_cObject, id)) {
      val = variable_c.rb_const_get(object_c.rb_cObject, id);
      if (val.get_type() == Value.T_MODULE) {
        return RClass(val);
      }
      error_c.rb_raise(error_c.rb_eTypeError, variable_c.rb_obj_classname(module)+" is not a module");
    }
    module = rb_define_module_id(id);
    variable_c.rb_class_tbl[id] = module;
    variable_c.rb_const_set(object_c.rb_cObject, id, module);

    return module;
  }

  // class.c:302
  public function
  rb_define_module_id(id:int):RClass
  {
    var mdl:RClass;

    mdl = rb_module_new();
    variable_c.rb_name_class(mdl, id);

    return mdl;
  }

  // class.c:292
  public function
  rb_module_new():RClass
  {
    var mdl:RClass = new RClass(null, null, object_c.rb_cModule);
    mdl.flags = Value.T_MODULE;
    return mdl;
  }

  public function rb_define_singleton_method(obj:Value, name:String, func:Function, argc:int):void {
    rb_define_method(rb_singleton_class(obj), name, func, argc);
  }


}
}
