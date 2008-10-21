
  protected var rb_global_tbl:Object;
  public var rb_class_tbl:Object;

  protected var autoload:int;
  protected var classpath:int;
  protected var tmp_classpath:int;


  public function
  Init_var_tables():void
  {
    rb_class_tbl = {};
    rb_global_tbl = {};
    autoload = rb_intern("__autoload__");
    classpath = rb_intern("__classpath__");
    tmp_classpath = rb_intern("__tmp_classpath__");
  }


  public function
  rb_name_class(klass:RClass, id:int):void
  {
    rb_iv_set(klass, "__classid__", ID2SYM(id));
    klass.name = rb_id2name(id);
  }

  // variable.c:1654
  public function rb_const_defined(klass:RClass, id:int):Boolean {
    return rb_const_defined_0(klass, id, false, true);
  }

  // variable.c:1439
  public function
  rb_const_get_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Value
  {
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
          if (exclude && tmp == rb_cObject && klass !=rb_cObject) {
            rb_warn("toplevel constant "+rb_id2name(id)+" referenced by "+
                    rb_class2name(klass)+"::"+rb_id2name(id));
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
  public function
  const_missing(klass:RClass, id:int):Value
  {
    return rb_funcall(klass, rb_intern("const_missing"), 1, ID2SYM(id));
  }

  // variable.c:1477
  public function
  rb_const_get(klass:RClass, id:int):Value
  {
    return rb_const_get_0(klass, id, false, true);
  }

  // variable.c:1623
  public function
  rb_const_defined_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Boolean
  {
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

  protected function
  generic_ivar_set(obj:RObject, id:String, val:*):void
  {
  }

  protected function
  generic_ivar_get(obj:RObject, id:String):*
  {
    return undefined;//return obj.iv_tbl[id];
  }

  protected function
  rb_ivar_set(obj:RObject, id:int, val:*):void
  {
    if (obj is RClass) {
      obj.iv_tbl[id] = val;
    }

  }

  protected function
  rb_iv_set(obj:RObject, name:String, val:*):void
  {
    rb_ivar_set(obj, rb_intern(name), val);
  }

  public function
  rb_const_set(obj:RObject, id:int, val:*):void
  {
    obj.iv_tbl[id] = val;
  }

  public function
  classname(klass:RClass):Value
  {
    var path:Value = Qnil;

    if (!klass) {
      klass = rb_cObject;
    }
    if (klass.iv_tbl[classpath] == undefined) {
      var classid:int = rb_intern("__classid__");

      if (klass.iv_tbl[classid] == undefined) {
        return find_class_path(klass);
      }
      path = klass.iv_tbl[classid];
      path = rb_str_dup(rb_id2str(SYM2ID(path)));
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

  public function
  rb_class_name(klass:RClass):Value
  {
    return rb_class_path(rb_class_real(klass));
  }

  public function
  rb_class2name(klass:RClass):String
  {
    return RString(rb_class_name(klass)).string;
  }

  public function
  rb_class_path(klass:RClass):Value
  {
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

  public function
  rb_set_class_path(klass:RClass, under:RClass, name:String):void
  {
    var str:RString;

    if (under == rb_cObject) {
      str = rb_str_new2(name);
    } else {
      str = rb_str_dup(RString(rb_class_path(under)));
      rb_str_cat2(str, "::");
      rb_str_cat2(str, name);
    }
    // TODO: @skipped freeze
    // OBJ_FREEZE(str);
    rb_ivar_set(klass, classpath, str);
  }

  public function
  rb_define_const(klass:RClass, name:String, val:Value):void
  {
    var id:int = rb_intern(name);

    if (!rb_is_const_id(id)) {
      rb_warn("rb_define_const: invalid name '"+name+"' for constant");
    }
    if (klass == rb_cObject) {
      // TODO: @skipped security check
      // rb_secure(4);
    }
    rb_const_set(klass, id, val);
  }

  public function
  rb_define_global_const(name:String, val:Value):void
  {
    rb_define_const(rb_cObject, name, val);
  }

  // variable.c:1660
  public function
  rb_const_defined_at(klass:RClass, id:int):Boolean
  {
    return rb_const_defined_0(klass, id, true, false);
  }

  public function
  rb_const_get_at(klass:RClass, id:int):Value
  {
    return rb_const_get_0(klass, id, true, false);
  }

  public function
  ivar_get(obj:Value, id:int, warn:Boolean):*
  {
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

  public function
  rb_ivar_get(obj:RObject, id:int):*
  {
   return ivar_get(obj, id, true);
  }

  public function
  rb_iv_get(obj:RObject, name:String):*
  {
    return rb_ivar_get(obj, rb_intern(name));
  }

  public function
  rb_obj_classname(obj:Value):String
  {
    return rb_class2name(CLASS_OF(obj));
  }

  public function
  find_class_path(klass:RClass):Value
  {
    // Loop through all defined constants searching for one that points at this class.
    // Only needed for anonymous classes that are then queried for their names
    return Qnil;
  }


