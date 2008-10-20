package ruby.internals
{
public class Variable_c
{
  protected var rc:RubyCore;

  public var error_c:Error_c;
  public var parse_y:Parse_y;
  public var object_c:Object_c;
  public var string_c:String_c;
  public var variable_c:Variable_c;

  protected var rb_global_tbl:Object;
  public var rb_class_tbl:Object;

  protected var autoload:int;
  protected var classpath:int;
  protected var tmp_classpath:int;


  public function Variable_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function
  Init_var_tables():void
  {
    rb_class_tbl = {};
    rb_global_tbl = {};
    autoload = parse_y.rb_intern("__autoload__");
    classpath = parse_y.rb_intern("__classpath__");
    tmp_classpath = parse_y.rb_intern("__tmp_classpath__");
  }


  public function
  rb_name_class(klass:RClass, id:int):void
  {
    rb_iv_set(klass, "__classid__", rc.ID2SYM(id));
    klass.name = parse_y.rb_id2name(id);
  }

  // variable.c:1654
  public function rb_const_defined(klass:RClass, id:int):Boolean {
    return rb_const_defined_0(klass, id, false, true);
  }

  // variable.c:1439
  public function rb_const_get_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Value {
    var value:Value, tmp:RClass;
    var mod_retry:Boolean = false;
    var loop:Boolean;

    tmp = klass;

    // retry:
    do {
      loop = false;

      while (rc.RTEST(tmp)) {
        if (tmp.iv_tbl && tmp.iv_tbl[id]) {
          value = tmp.iv_tbl[id];
          if (value == rc.Qundef) {// && NIL_P(autoload_file(klass, id))) {
            continue;
          }
          if (exclude && tmp == object_c.rb_cObject && klass !=object_c.rb_cObject) {
            error_c.rb_warn("toplevel constant "+parse_y.rb_id2name(id)+" referenced by "+
                    variable_c.rb_class2name(klass)+"::"+parse_y.rb_id2name(id));
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
  public function const_missing(klass:RClass, id:int):Value {
    return rb_funcall(klass, parse_y.rb_intern("const_missing"), 1, ID2SYM(id));
  }

  // variable.c:1477
  public function rb_const_get(klass:RClass, id:int):Value {
    return rb_const_get_0(klass, id, false, true);
  }

  // variable.c:1623
  public function rb_const_defined_0(klass:RClass, id:int, exclude:Boolean, recurse:Boolean):Boolean {
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
    rb_ivar_set(obj, parse_y.rb_intern(name), val);
  }

  public function rb_const_set(obj:RObject, id:int, val:*):void {
    obj.iv_tbl[id] = val;
  }

  public function
  classname(klass:RClass):Value
  {
    var path:Value = rc.Qnil;

    if (!klass) {
      klass = object_c.rb_cObject;
    }
    if (klass.iv_tbl[classpath] == undefined) {
      var classid:int = parse_y.rb_intern("__classid__");

      if (klass.iv_tbl[classid] == undefined) {
        return find_class_path(klass);
      }
      path = klass.iv_tbl[classid];
      path = string_c.rb_str_dup(parse_y.rb_id2str(rc.SYM2ID(path)));
      // OBJ_FREEZE(path);
      klass.iv_tbl[classpath] = path;
      delete klass.iv_tbl[classid];

    } else {
      path = klass.iv_tbl[classpath];
    }
    if (!path.is_string()) {
      error_c.rb_bug("class path is not set properly");
    }
    return path;
  }

  public function
  rb_class_name(klass:RClass):Value
  {
    return rb_class_path(object_c.rb_class_real(klass));
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
        if (object_c.rb_obj_class(klass) == object_c.rb_cModule) {
          s = "Module";
        } else {
          s = rb_class2name(klass.klass);
        }
      }
      path = string_c.rb_str_new("#<"+s+":"+klass.toString()+">");
      // OBJ_FREEZE(path)
      rb_ivar_set(klass, tmp_classpath, path);

      return path;
    }
  }

  public function
  rb_set_class_path(klass:RClass, under:RClass, name:String):void
  {
    var str:RString;

    if (under == object_c.rb_cObject) {
      str = string_c.rb_str_new2(name);
    } else {
      str = string_c.rb_str_dup(RString(rb_class_path(under)));
      string_c.rb_str_cat2(str, "::");
      string_c.rb_str_cat2(str, name);
    }
    // OBJ_FREEZE(str);
    rb_ivar_set(klass, classpath, str);
  }

  public function
  rb_define_const(klass:RClass, name:String, val:Value):void
  {
    var id:int = parse_y.rb_intern(name);

    if (!parse_y.rb_is_const_id(id)) {
      error_c.rb_warn("rb_define_const: invalid name '"+name+"' for constant");
    }
    if (klass == object_c.rb_cObject) {
      // rb_secure(4);
    }
    rb_const_set(klass, id, val);
  }

  public function
  rb_define_global_const(name:String, val:Value):void
  {
    rb_define_const(object_c.rb_cObject, name, val);
  }

  public function
  rb_const_defined_at(cbase:RClass, id:int):Boolean
  {
    trace("stub rb_const_defined_at returning false.");
    return false;
  }

  public function
  rb_const_get_at(cbase:RClass, id:int):Value
  {
    trace("stub rb_const_get_at returning null.");
    return null;
  }

  public function ivar_get(obj:Value, id:int, warn:Boolean):* {
    var val:*;

    switch (obj.get_type()) {
      case Value.T_OBJECT:
        val = RObject(obj).iv_tbl[id];
        if (val != undefined && val != rc.Qundef) {
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
    return rc.Qnil;
  }

  public function rb_ivar_get(obj:RObject, id:int):* {
   return ivar_get(obj, id, true);
  }

  public function rb_iv_get(obj:RObject, name:String):* {
    return rb_ivar_get(obj, parse_y.rb_intern(name));
  }

  public function
  rb_obj_classname(obj:Value):String
  {
    return rb_class2name(rc.CLASS_OF(obj));
  }


}
}
