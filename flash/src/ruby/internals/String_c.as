package ruby.internals
{
public class String_c
{
  public var rc:RubyCore;


  public var rb_cString:RClass;
  public var rb_cSymbol:RClass;

  public var id_to_s:int;

  public function
  rb_str_intern(s:Value):Value
  {
    // TODO: @skipped
    var str:Value = s;//RB_GC_GUARD(s);
    var sym:Value;
    var id:int, id2:int;

    id = rc.parse_y.rb_intern_str(str);
    sym = rc.ID2SYM(id);
    id2 = rc.SYM2ID(sym);

    if (id != id2) {
      var name:String = rc.parse_y.rb_id2name(id2);

      if (name) {
        rc.error_c.rb_raise(rc.error_c.rb_eRuntimeError, "symbol table overflow ("+name+" given for "+
                    rc.RSTRING_PTR(str)+")");
      } else {
        rc.error_c.rb_raise(rc.error_c.rb_eRuntimeError, "symbol table overflow (symbol "+rc.RSTRING_PTR(str)+")");
      }
    }
    return sym;
  }

  // string.c
  public function
  rb_obj_as_string(obj:Value):RString
  {
    var val:Value;

    if (obj && obj.get_type() == Value.T_STRING) {
      return RString(obj);
    }
    val = rc.vm_eval_c.rb_funcall(obj, id_to_s, 0);
    if (val.get_type() != Value.T_STRING) {
      return rc.object_c.rb_any_to_s(obj);
    }
    // TODO: @skipped
    // OBJ_TAINTED
    return RString(val);
  }

  public function
  str_new(klass:RClass, str:String):RString
  {
    var res:RString = new RString(klass);
    res.string = str;
    return res;
  }

  public function
  rb_str_dup(str:RString):RString
  {
    var dup:RString = new RString(str.klass);
    dup.string = str.string;
    return dup;
  }

  public function
  rb_str_cat2(str:RString, ptr:String):RString
  {
    str.string += ptr;
    return str;
  }

  public function rb_str_new(str:String):RString
  {
    return str_new(rb_cString, str);
  }

  public function rb_str_new_cstr(str:String):RString
  {
    return str_new(rb_cString, str);
  }

  public function rb_str_new2(str:String):RString
  {
    return rb_str_new_cstr(str);
  }


  // string.c
  public function
  rb_to_id(name:Value):int
  {
    var tmp:Value;
    var id:int;

    switch (name.get_type()) {
      default:
        tmp = rb_check_string_type(name);
        if (rc.NIL_P(tmp)) {
          rc.error_c.rb_raise(rc.error_c.rb_eTypeError, rc.RSTRING_PTR(rc.object_c.rb_inspect(name))+" is not a symbol");
        }
        name = tmp;
        // Intentional fall through
      case Value.T_STRING:
        name = rb_str_intern(name);
        // Intentional fall through
      case Value.T_SYMBOL:
        return rc.SYM2ID(name);
    }
    return id;
  }

  // string.c:1132
  public function
  rb_check_string_type(str:Value):Value
  {
    str = rc.object_c.rb_check_convert_type(str, Value.T_STRING, "String", "to_str");
    return str;
  }

  // string.c:419
  public function
  rb_enc_str_new(ptr:String, enc:String):Value
  {
    var str:RString = rb_str_new(ptr);
    // TODO: @skipped
    // rb_enc_associate(str, enc);
    return str;
  }


}
}
