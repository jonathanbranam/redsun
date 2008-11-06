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
    if (rc.OBJ_TAINTED(obj)) rc.OBJ_TAINT(val);
    return RString(val);
  }

  public function
  str_alloc(klass:RClass):RString
  {
    return new RString(klass);
  }

  public function
  str_new(klass:RClass, str:String):RString
  {
    var res:RString = str_alloc(klass);
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

  // string.c:446
  public function
  rb_usascii_str_new_cstr(ptr:String):RString
  {
    var str:RString = rb_str_new2(ptr);
    // ENCODING_CODERANGE_SET(str, rb_usascii_encindex(), ENC_CODERANGE_7BIT);
    return str;
  }

  public function
  rb_usascii_str_new2(ptr:String):RString
  {
    return rb_usascii_str_new_cstr(ptr);
  }

  public function
  rb_usascii_str_new(ptr:String):RString
  {
    return rb_usascii_str_new_cstr(ptr);
  }

  public function
  rb_str_cat2(str:RString, ptr:String):RString
  {
    str.string += ptr;
    return str;
  }

  // string.c:529
  public function
  str_new4(klass:RClass, str:Value):RString
  {
    var str2:RString;

    str2 = str_alloc(klass);
    // STR_SET_NOEMBED(str2)
    // TODO: SHARED strings
    str2.string = RString(str).string;
    rc.OBJ_INFECT(str2, str);
    return str2;
  }

  public function
  rb_str_new_frozen(orig:Value):Value
  {
    var klass:RClass, str:RString;

    if (rc.OBJ_FROZEN(orig)) return orig;
    klass = rc.object_c.rb_obj_class(orig);
    str = str_new4(klass, orig);
    rc.OBJ_FREEZE(str);
    return str;
  }

  public function
  rb_str_new4(orig:Value):Value
  {
    return rb_str_new_frozen(orig);
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

  // string.c:1639
  public function
  rb_str_buf_append(str:RString, str2:RString):RString
  {
    str.string += str2.string;
    rc.OBJ_INFECT(str, str2);
    return str;
  }

  // string.c:1697
  public function
  rb_str_concat(str1:RString, str2:Value):Value
  {
    if (rc.FIXNUM_P(str2)) {
      var c:int = rc.FIX2LONG(str2);
      str1.string += String.fromCharCode(c);
      return str1;
    }
    return rb_str_append(str1, str2);
  }

  // string.c:635
  public function
  rb_str_to_str(str:Value):RString
  {
    return RString(rc.object_c.rb_convert_type(str, Value.T_STRING, "String", "to_str"));
  }

  // string.c:1103
  public function
  rb_string_value(ptr:Value):RString
  {
    var s:Value = ptr;
    if (rc.TYPE(s) != Value.T_STRING) {
      s = rb_str_to_str(s);
    }
    return RString(s);
  }

  // string.c:1655
  public function
  rb_str_append(str:RString, val2:Value):RString
  {
    // Reallocation code skipped
    rc.OBJ_INFECT(str, str2);
    var str2:RString = rb_string_value(val2);
    return rb_str_buf_append(str, str2);
  }

  // string.c:1906
  public function
  rb_str_comparable(str1:Value, str2:Value):Boolean
  {
    // TODO: @skipped encoding checks
    return true;
  }

  // string.c:1951
  public function
  rb_str_equal(str1:Value, str2:Value):Value
  {
    if (str1 == str2) return rc.Qtrue;
    if (rc.TYPE(str2) != Value.T_STRING) {
      if (!rc.vm_method_c.rb_respond_to(str2, rc.parse_y.rb_intern("to_str"))) {
        return rc.Qfalse;
      }
      return rc.object_c.rb_equal(str2, str1);
    }
    if (!rb_str_comparable(str1, str2)) return rc.Qfalse;
    if (RString(str1).string == RString(str2).string) {
      return rc.Qtrue;
    }
    return rc.Qfalse;
  }

  // string.c:6622
  public function
  Init_String():void
  {
    rb_cString = rc.class_c.rb_define_class("String", rc.object_c.rb_cObject);

    // TODO: Lots of String methods

    rb_cSymbol = rc.class_c.rb_define_class("Symbol", rc.object_c.rb_cObject);

    // TODO: Lots of Symbol methods

  }


}
}
