package ruby.internals
{
public class String_c
{
  protected var rc:RubyCore;
  public var parse_y:Parse_y;
  public var error_c:Error_c;

  public var rb_cString:RClass;
  public var rb_cSymbol:RClass;

  public var id_to_s:int;

  public function String_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function rb_str_intern(s:Value):Value {
    var str:Value = s;//RB_GC_GUARD(s);
    var sym:Value;
    var id:int, id2:int;

    id = parse_y.rb_intern_str(str);
    sym = rc.ID2SYM(id);
    id2 = rc.SYM2ID(sym);

    if (id != id2) {
      var name:String = parse_y.rb_id2name(id2);

      if (name) {
        error_c.rb_raise(error_c.rb_eRuntimeError, "symbol table overflow ("+name+" given for "+
                    rc.RSTRING_PTR(str)+")");
      } else {
        error_c.rb_raise(error_c.rb_eRuntimeError, "symbol table overflow (symbol "+rc.RSTRING_PTR(str)+")");
      }
    }
    return sym;
  }

  // string.c
  public function
  rb_obj_as_string(obj:Value):RString
  {
    var val:Value;

    if (obj.get_type() == Value.T_STRING) {
      return RString(obj);
    }
    val = rb_funcall(obj, id_to_s, 0);
    if (val.get_type() != Value.T_STRING) {
      return rb_any_to_s(obj);
    }
    // OBJ_TAINTED
    return RString(val);
  }

  public function str_new(klass:RClass, str:String):RString {
    var res:RString = new RString(klass);
    res.string = str;
    return res;
  }

  public function rb_str_dup(str:RString):RString {
    var dup:RString = new RString(str.klass);
    dup.string = str.string;
    return dup;
  }

  public function rb_str_cat2(str:RString, ptr:String):RString {
    str.string += ptr;
    return str;
  }

  public function rb_str_new(str:String):RString {
    return str_new(rb_cString, str);
  }

  public function rb_str_new_cstr(str:String):RString {
    return str_new(rb_cString, str);
  }

  public function rb_str_new2(str:String):RString {
    return rb_str_new_cstr(str);
  }


}
}
