package ruby.internals
{
public class Class_c
{


  import ruby.internals.RClass;

  public var rc:RubyCore;

  public function
  rb_singleton_class_attached(klass:RClass, obj:RObject):void
  {
    if (klass.is_singleton()) {
      var attached:int = rc.rc.parse_y.rb_intern("__attached__");
      klass.iv_tbl[attached] = obj;
    }
  }

  public function
  rb_class_boot(super_class:RClass):RClass
  {
    var klass:RClass = new RClass(null, super_class, rc.object_c.rb_cClass);
    // TODO: @skipped
    // OBJ_INFECT(klass, super_class);
    return klass;
  }

  public function
  rb_make_metaclass(obj:RObject, super_class:RClass):RClass {
    if (obj.is_class() && RClass(obj).is_singleton()) {
      return obj.klass = rc.object_c.rb_cClass;
    } else {
      var klass:RClass = rb_class_boot(super_class);
      var s:uint = RClass.FL_SINGLETON;
      klass.flags |= RClass.FL_SINGLETON;
      klass.flags = klass.flags | s;
      if (obj.get_type() == Value.T_CLASS) {
        klass.name = RClass(obj).name+"Singleton";
      } else {
        klass.name = "objectSingleton";
      }
      obj.klass = klass;
      rb_singleton_class_attached(klass, obj);

      var metasuper:RClass = rc.object_c.rb_class_real(super_class).klass;
      if (metasuper) {
        klass.klass = metasuper;
      }
      return klass;
    }
  }


  public function
  rb_singleton_class(obj:Value):RClass
  {
    // TODO: @skipped
    // Special casing skipped

    var klass:RClass;

    var oobj:RObject = RObject(obj);
    if (oobj.klass.is_singleton() && rc.variable_c.rb_iv_get(oobj.klass, "__attached__") == obj) {
      klass = oobj.klass;
    } else {
      klass = rb_make_metaclass(oobj, oobj.klass);
    }

    // TODO: @skipped
    // Taint, trust, frozen checks skipped

    return klass;
  }

  public function
  rb_define_class_id(id:int, super_class:RClass):RClass
  {
    var klass:RClass;

    if (!super_class) {
      super_class = rc.object_c.rb_cObject;
    }

    klass = rc.object_c.rb_class_new(super_class);
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

    id = rc.rc.parse_y.rb_intern(name);
    if (rc.variable_c.rb_const_defined(rc.object_c.rb_cObject, id)) {
      val = rc.variable_c.rb_const_get(rc.object_c.rb_cObject, id);
      if (val.get_type() != Value.T_CLASS) {
        rc.error_c.rc.error_c.rb_raise(rc.error_c.rc.error_c.rb_eTypeError, name+" is not a class");
      }
      klass = RClass(val);
      if (rc.object_c.rb_class_real(klass.super_class) != super_class) {
        rc.error_c.rb_name_error(id, name+" is already defined");
      }
      return klass;
    }
    if (!super_class) {
      rc.error_c.rc.error_c.rb_warn("no super class for '"+name+"', Object assumed");
    }

    klass = rb_define_class_id(id, super_class);
    rc.variable_c.rb_class_tbl[id] = klass;
    rc.variable_c.rb_name_class(klass, id);
    rc.variable_c.rb_const_set(rc.object_c.rb_cObject, id, klass);
    rb_class_inherited(super_class, klass);

    return klass;
  }

  // class.c:263
  public function
  rb_define_class_under(outer:RClass, name:String, super_class:RClass):RClass
  {
    var klass:RClass;
    var id:int;

    id = rc.rc.parse_y.rb_intern(name);
    if (rc.variable_c.rb_const_defined_at(outer, id)) {
      var val:Value = rc.variable_c.rb_const_get_at(outer, id);
      if (val.get_type() != Value.T_CLASS) {
        rc.error_c.rc.error_c.rb_raise(rc.error_c.rc.error_c.rb_eTypeError, name+" is not a class");
      }
      klass = RClass(val);
      if (rc.object_c.rb_class_real(klass.super_class) != super_class) {
        rc.error_c.rb_name_error(id, name+" is already defined");
      }
      return klass;
    }
    if (!super_class) {
      rc.error_c.rc.error_c.rb_warn("no super class for '"+rc.variable_c.rb_class2name(outer)+"::"+name+"', Object assumed");
    }
    klass = rb_define_class_id(id, super_class);
    rc.variable_c.rb_set_class_path(klass, outer, name);
    rc.variable_c.rb_const_set(outer, id, klass);
    rb_class_inherited(super_class, klass);

    return klass;
  }

  public function
  rb_class_inherited(super_class:RClass, klass:RClass):Value
  {
    var inherited:int;
    if (!super_class) {
      super_class = rc.object_c.rb_cObject;
    }
    inherited = rc.rc.parse_y.rb_intern("inherited");
    return rc.vm_eval_c.rb_funcall(super_class, inherited, 1, klass);
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
    rb_define_module_function(rc.object_c.rb_mKernel, name, func, argc);
  }

  // class.c:778
  public function
  rb_define_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rc.vm_method_c.rb_add_method(klass, rc.rc.parse_y.rb_intern(name), rc.NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }

  // class.c:772
  public function
  rb_define_method_id(klass:RClass, name:int, func:Function, argc:int):void
  {
    rc.vm_method_c.rb_add_method(klass, name, rc.NEW_CFUNC(func, argc), Node.NOEX_PUBLIC);
  }


  // class.c:784
  public function
  rb_define_protected_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rc.vm_method_c.rb_add_method(klass, rc.rc.parse_y.rb_intern(name), rc.NEW_CFUNC(func, argc), Node.NOEX_PROTECTED);
  }

  // class.c:790
  public function
  rb_define_private_method(klass:RClass, name:String, func:Function, argc:int):void
  {
    rc.vm_method_c.rb_add_method(klass, rc.rc.parse_y.rb_intern(name), rc.NEW_CFUNC(func, argc), Node.NOEX_PRIVATE);
  }


  // class.c:380
  public function
  rb_include_module(klass:RClass, module_val:Value):void
  {
    var p:RClass, c:RClass;
    var changed:Boolean = false;

    // TODO: @skipped
    // frozen, untrusted stuff

    if (rc.TYPE(module_val) != Value.T_MODULE) {
      rc.Check_Type(module_val, Value.T_MODULE);
    }
    var module:RClass = RClass(module_val);

    // TODO: @skipped
    // OBJ_INFECT(klass, module);
    c = klass;
    while (module) {
      var superclass_seen:Boolean = false;

      if (klass.m_tbl == module.m_tbl) {
        rc.error_c.rc.error_c.rb_raise(rc.error_c.rc.error_c.rb_eArgError, "cyclic include detected");
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
      // TODO: @skipped
      // rb_clear_cache();
    }
  }

  // class.c:354
  protected function
  include_class_new(module:RClass, super_class:RClass):RClass
  {
    var klass:RClass = new RClass(null, super_class, rc.object_c.rb_cClass);

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
    // TODO: @skipped
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

    id = rc.rc.parse_y.rb_intern(name);
    if (rc.variable_c.rb_const_defined(rc.object_c.rb_cObject, id)) {
      val = rc.variable_c.rb_const_get(rc.object_c.rb_cObject, id);
      if (val.get_type() == Value.T_MODULE) {
        return RClass(val);
      }
      rc.error_c.rc.error_c.rb_raise(rc.error_c.rc.error_c.rb_eTypeError, rc.variable_c.rb_obj_classname(module)+" is not a module");
    }
    module = rb_define_module_id(id);
    rc.variable_c.rb_class_tbl[id] = module;
    rc.variable_c.rb_const_set(rc.object_c.rb_cObject, id, module);

    return module;
  }

  // class.c:302
  public function
  rb_define_module_id(id:int):RClass
  {
    var mdl:RClass;

    mdl = rb_module_new();
    rc.variable_c.rb_name_class(mdl, id);

    return mdl;
  }

  // class.c:292
  public function
  rb_module_new():RClass
  {
    var mdl:RClass = new RClass(null, null, rc.object_c.rb_cModule);
    mdl.flags = Value.T_MODULE;
    return mdl;
  }

  public function rb_define_singleton_method(obj:Value, name:String, func:Function, argc:int):void {
    rb_define_method(rb_singleton_class(obj), name, func, argc);
  }

}

}
