package ruby.internals
{
public class Variable_c
{
  public var rc:RubyCore;

  import ruby.internals.RClass;

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
    autoload = rc.parse_y.rb_intern("__autoload__");
    classpath = rc.parse_y.rb_intern("__classpath__");
    tmp_classpath = rc.parse_y.rb_intern("__tmp_classpath__");
  }


  public function
  rb_name_class(klass:RClass, id:int):void
  {
    rb_iv_set(klass, "__classid__", rc.ID2SYM(id));
    klass.name = rc.parse_y.rb_id2name(id);
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

      while (rc.RTEST(tmp)) {
        if (tmp.iv_tbl && tmp.iv_tbl[id] != undefined) {
          value = tmp.iv_tbl[id];
          if (value == rc.Qundef) {// && NIL_P(autoload_file(klass, id))) {
            continue;
          }
          if (exclude && tmp == rc.object_c.rb_cObject && klass != rc.object_c.rb_cObject) {
            rc.error_c.rb_warn("toplevel constant "+rc.parse_y.rb_id2name(id)+" referenced by "+
                    rb_class2name(klass)+"::"+rc.parse_y.rb_id2name(id));
          }
          return value;
        }
        if (!recurse && klass != rc.object_c.rb_cObject) {
          break;
        }
        tmp = tmp.super_class;
      }
      if (!exclude && !mod_retry && klass.BUILTIN_TYPE() == Value.T_MODULE) {
        mod_retry = true;
        tmp = rc.object_c.rb_cObject;
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
    return rc.vm_eval_c.rb_funcall(klass, rc.parse_y.rb_intern("const_missing"), 1, rc.ID2SYM(id));
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
          if (value == rc.Qundef) {// && NIL_P(autoload_file(klass, id))) {
            return false;
          } else {
            return true;
          }
        }
        if (!recurse && klass != rc.object_c.rb_cObject) {
          break;
        }
        tmp = tmp.super_class;
      }
      if (!exclude && !mod_retry && klass.BUILTIN_TYPE() == Value.T_MODULE) {
        mod_retry = true;
        tmp = rc.object_c.rb_cObject;
        // goto retry;
        loop = true;
      }
    } while (loop);
    return false;
  }

  protected function
  generic_ivar_set(obj:Value, id:int, val:*):void
  {
    rc.error_c.rb_bug("generic ivar set");
  }

  protected function
  generic_ivar_get(obj:Value, id:int):*
  {
    rc.error_c.rb_bug("generic ivar get");
    return undefined;
  }

  public function
  rb_iv_set(obj:Value, name:String, val:*):void
  {
    rb_ivar_set(obj, rc.parse_y.rb_intern(name), val);
  }

  // variable.c:1666
  public function
  mod_av_set(klass:Value, id:int, val:Value, isconst:Boolean):void
  {
    var dest:String = isconst ? "constant" : "class variable";

    if (!rc.OBJ_UNTRUSTED(klass) && rc.rb_safe_level() >= 4) {
      rc.error_c.rb_raise(rc.error_c.rb_eSecurityError, "Insecure: can't set "+dest);
    }
    if (rc.OBJ_FROZEN(klass)) {
      if (klass.BUILTIN_TYPE() == Value.T_MODULE) {
        rc.error_c.rb_error_frozen("module");
      }
      else {
        rc.error_c.rb_error_frozen("class");
      }
    }
    if (!RClass(klass).iv_tbl) {
      RClass(klass).iv_tbl = new Object();
    }
    else if (isconst) {
      var value:Value = rc.Qfalse;

      if (RClass(klass).iv_tbl[id] != undefined) {
        value = RClass(klass).iv_tbl[id];
        if (value == rc.Qundef) {
          rc.error_c.rb_bug("autoload_delete not implemented.");
          // autoload_delete(klass, id);
        } else {
          rc.error_c.rb_warn("already initialized " + dest + " " +
                             rc.parse_y.rb_id2name(id));
        }
      }
    }

    if (isconst) {
      rc.vm_c.rb_vm_change_state();
    }
    RClass(klass).iv_tbl[id] = val;
  }

  public function
  rb_const_set(klass:Value, id:int, val:*):void
  {
    if (rc.NIL_P(klass)) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError,
                          "no class/module to define constant " +
                          rc.parse_y.rb_id2name(id));
    }
    mod_av_set(klass, id, val, true);
  }

  public function
  classname(klass:RClass):Value
  {
    var path:Value = rc.Qnil;

    if (!klass) {
      klass = rc.object_c.rb_cObject;
    }
    if (klass.iv_tbl[classpath] == undefined) {
      var classid:int = rc.parse_y.rb_intern("__classid__");

      if (klass.iv_tbl[classid] == undefined) {
        return find_class_path(klass);
      }
      path = klass.iv_tbl[classid];
      path = rc.string_c.rb_str_dup(rc.parse_y.rb_id2str(rc.SYM2ID(path)));
      rc.OBJ_FREEZE(path);
      klass.iv_tbl[classpath] = path;
      delete klass.iv_tbl[classid];

    } else {
      path = klass.iv_tbl[classpath];
    }
    if (!path.is_string()) {
      rc.error_c.rb_bug("class path is not set properly");
    }
    return path;
  }

  public function
  rb_class_name(klass:RClass):Value
  {
    return rb_class_path(rc.object_c.rb_class_real(klass));
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

    if (!rc.NIL_P(path)) {
      return path;
    }
    if (klass.iv_tbl[tmp_classpath] != undefined) {
      return path;
    } else {
      var s:String = "Class";
      if (klass.is_module()) {
        if (rc.object_c.rb_obj_class(klass) == rc.object_c.rb_cModule) {
          s = "Module";
        } else {
          s = rb_class2name(klass.klass);
        }
      }
      path = rc.string_c.rb_str_new("#<"+s+":"+klass.toString()+">");
      rc.OBJ_FREEZE(path)
      rb_ivar_set(klass, tmp_classpath, path);

      return path;
    }
  }

  public function
  rb_set_class_path(klass:RClass, under:RClass, name:String):void
  {
    var str:RString;

    if (under == rc.object_c.rb_cObject) {
      str = rc.string_c.rb_str_new2(name);
    } else {
      str = rc.string_c.rb_str_dup(RString(rb_class_path(under)));
      rc.string_c.rb_str_cat2(str, "::");
      rc.string_c.rb_str_cat2(str, name);
    }
    rc.OBJ_FREEZE(str);
    rb_ivar_set(klass, classpath, str);
    klass.name = name;
  }

  public function
  rb_define_const(klass:RClass, name:String, val:Value):void
  {
    var id:int = rc.parse_y.rb_intern(name);

    if (!rc.parse_y.rb_is_const_id(id)) {
      rc.error_c.rb_warn("rb_define_const: invalid name '"+name+"' for constant");
    }
    if (klass == rc.object_c.rb_cObject) {
      // TODO: @skipped security check
      // rb_secure(4);
    }
    rb_const_set(klass, id, val);
  }

  public function
  rb_define_global_const(name:String, val:Value):void
  {
    rb_define_const(rc.object_c.rb_cObject, name, val);
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
    var ptr:Array;
    var iv_index_tbl:Object;
    var len:int;
    var index:int;

    switch (obj.get_type()) {
      case Value.T_OBJECT:
        len = rc.ROBJECT_NUMIV(obj);
        ptr = rc.ROBJECT_IVPTR(obj);
        iv_index_tbl = rc.ROBJECT_IV_INDEX_TBL(obj);
        if (!iv_index_tbl) break;
        if (iv_index_tbl[id] == undefined) break;
        else index = iv_index_tbl[id];
        val = ptr[index];
        if (val != rc.Qundef)
          return val;
        break;
      case Value.T_CLASS:
      case Value.T_MODULE:
        val = RClass(obj).iv_tbl[id];
        if (val != undefined) {
          return val;
        }
        break;
      default:
        rc.error_c.rb_bug("generic ivar not implemented");
        //if (FL_TEST(obj, FL_EXIVAR) || rb_special_const_p(obj)) {
        //  return generic_ivar_get(obj, id, warn);
        //}
        break;
    }
    if (warn) {
      rc.error_c.rb_warning("instance variable "+rc.parse_y.rb_id2name(id)+" not initialized");
    }
    return rc.Qnil;
  }

  public function
  rb_ivar_get(obj:Value, id:int):*
  {
   return ivar_get(obj, id, true);
  }

  // variable.c:985
  public function
  rb_attr_get(obj:Value, id:int):Value
  {
    return ivar_get(obj, id, false);
  }

  // variable.c:991
  public function
  rb_ivar_set(obj:Value, id:int, val:Value):Value
  {
    var iv_index_tbl:Object;
    var index:int;
    var i:int, len:int;
    var ivar_extended:Boolean;

    if (!rc.OBJ_UNTRUSTED(obj) && rc.rb_safe_level() >= 4) {
      rc.error_c.rb_raise(rc.error_c.rb_eSecurityError, "Insecure: can't modify instance variable");
    }
    if (rc.OBJ_FROZEN(obj)) rc.error_c.rb_error_frozen("object");
    switch (rc.TYPE(obj)) {
      case Value.T_OBJECT:
        iv_index_tbl = rc.ROBJECT_IV_INDEX_TBL(obj);
        if (!iv_index_tbl) {
          var klass:RClass = rc.object_c.rb_obj_class(obj);
          iv_index_tbl = RClass(klass).iv_index_tbl;
          if (!iv_index_tbl) {
            iv_index_tbl = RClass(klass).iv_index_tbl = new Object();
          }
        }
        ivar_extended = false;
        if (iv_index_tbl[id] == undefined) {
          if (iv_index_tbl.num_entries == undefined) {
            index = iv_index_tbl.num_entries = 0;
          } else {
            index = iv_index_tbl.num_entries;
          }
          iv_index_tbl[id] = index;
          iv_index_tbl.num_entries = iv_index_tbl.num_entries+1;
          ivar_extended = true;
        } else {
          index = iv_index_tbl[id];
        }
        // Bunch of code to manage the size of the array which
        // isn't needed since the array will automatically change size
        // for us in AS3.
        len = rc.ROBJECT_NUMIV(obj);
        var ptr:Array = rc.ROBJECT_IVPTR(obj);
        if (len <= index) {
          var newsize:int = (index+1) + (index+1)/4;
          if (!ptr) {
            ptr = RObject(obj).ivptr = new Array(newsize);
          }
          for (; len < newsize; len++) {
            ptr[len] = rc.Qundef;
          }
          RObject(obj).iv_index_tbl = iv_index_tbl;
        }
        ptr[index] = val;
        break;
      case Value.T_CLASS:
      case Value.T_MODULE:
        if (!RClass(obj).iv_tbl) RClass(obj).iv_tbl = new Object();
        RClass(obj).iv_tbl[id] = val;
        break;
      default:
        generic_ivar_set(obj, id, val);
        break;
    }
    return val;
  }

  public function
  rb_iv_get(obj:Value, name:String):*
  {
    return rb_ivar_get(obj, rc.parse_y.rb_intern(name));
  }

  public function
  rb_obj_classname(obj:Value):String
  {
    return rb_class2name(rc.CLASS_OF(obj));
  }

  public function
  find_class_path(klass:RClass):Value
  {
    // Loop through all defined constants searching for one that points at this class.
    // Only needed for anonymous classes that are then queried for their names
    return rc.Qnil;
  }

  // variable.c:1648
  public function
  rb_const_defined_from(klass:RClass, id:int):Boolean
  {
    return rb_const_defined_0(klass, id, true, true);
  }

  // variable.c:1471
  public function
  rb_const_get_from(klass:RClass, id:int):Value
  {
    return rb_const_get_0(klass, id, true, true);
  }

}
}
