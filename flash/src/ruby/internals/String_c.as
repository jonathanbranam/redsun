
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

    id = rb_intern_str(str);
    sym = ID2SYM(id);
    id2 = SYM2ID(sym);

    if (id != id2) {
      var name:String = rb_id2name(id2);

      if (name) {
        rb_raise(rb_eRuntimeError, "symbol table overflow ("+name+" given for "+
                    RSTRING_PTR(str)+")");
      } else {
        rb_raise(rb_eRuntimeError, "symbol table overflow (symbol "+RSTRING_PTR(str)+")");
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
    val = rb_funcall(obj, id_to_s, 0);
    if (val.get_type() != Value.T_STRING) {
      return rb_any_to_s(obj);
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
        if (NIL_P(tmp)) {
          rb_raise(rb_eTypeError, RSTRING_PTR(rb_inspect(name))+" is not a symbol");
        }
        name = tmp;
        // Intentional fall through
      case Value.T_STRING:
        name = rb_str_intern(name);
        // Intentional fall through
      case Value.T_SYMBOL:
        return SYM2ID(name);
    }
    return id;
  }

  // string.c:1132
  public function
  rb_check_string_type(str:Value):Value
  {
    str = rb_check_convert_type(str, Value.T_STRING, "String", "to_str");
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


