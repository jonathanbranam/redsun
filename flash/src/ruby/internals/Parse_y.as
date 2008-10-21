
  import mx.utils.StringUtil;

  import ruby.internals.Id;
    public function
  rb_intern_str(str:Value):int
  {
    var enc:String;
    var id:int;

    // deal with encoding

    id = rb_intern3(RSTRING_PTR(str), enc);
    return id;
  }

  public function
  rb_usascii_encoding():String
  {
    return "ASCII";
  }

  protected var global_symbols__sym_id:Dictionary = new Dictionary();
  protected var global_symbols__id_str:Dictionary = new Dictionary();
  protected var global_symbols__last_id:int = Id.tLAST_TOKEN;

  public function
  rb_intern3(name:String, enc:String):int
  {
    var id:int;

    if (global_symbols__sym_id[name] != undefined) {
      return global_symbols__sym_id[name];
    }

    var m:int = 0;
    var len:int = name.length;
    var c:int;
    var c_str:String;

    switch (name.charAt()) {
      case "$":
        id |= Id.ID_GLOBAL;
        m++;
        // handle special global
        break;
      case "@":
        if (name.charAt(1) == "@") {
          id |= Id.ID_CLASS;
          m++;
        } else {
          id |= Id.ID_INSTANCE;
        }
        m++;
        break;
      default:
        c = name.charCodeAt(0);
        // TODO: @skipped check for operators
        if (name.charAt(len-1) == "=") {
          // attribute assignment
          id = rb_intern3(name.substr(0, len-1), enc);
          if (id > Id.tLAST_TOKEN && !is_attrset_id(id)) {
            // TODO: @skipped encoding
            //enc = rb_enc_get(rb_id2str(id));
            id = rb_id_attrset(id);
            // goto id_register;
          }
        }
        else if (rb_enc_isupper(name.charAt(), enc)) {
          id = Id.ID_CONST;
        }
        else {
          id = Id.ID_LOCAL;
        }
        break;
    }

    global_symbols__last_id++;
    id |= (global_symbols__last_id << Id.ID_SCOPE_SHIFT);

    return register_symid(id, name, enc);
  }

  public function
  rb_enc_isupper(char:String, enc:String):Boolean
  {
    // TODO: @skipped encoding support
    // String is upper if it is the same when uppercased
    return char.toUpperCase() == char;
  }

  // parse.y:7792
  public function
  rb_id_attrset(id:int):int
  {
    id &= ~Id.ID_SCOPE_MASK;
    id |= Id.ID_ATTRSET;
    return id;
  }

  public function
  register_symid(id:int, name:String, enc:String):int
  {
    var str:Value = rb_enc_str_new(name, enc);
    // TODO: @skipped freeze
    // OBJ_FREEZE(str);
    global_symbols__sym_id[name] = id;
    global_symbols__id_str[id] = str;
    return id;
  }

  public function
  rb_intern2(name:String):int
  {
    return rb_intern3(name, rb_usascii_encoding());
  }

  public function
  rb_intern(name:String):int
  {
    return rb_intern2(name);
  }

  public function
  rb_intern_const(name:String):int
  {
    return rb_intern(name);
  }

  public function
  rb_id2name(id:int):String
  {
    var str:RString = rb_id2str(id);
    return str.string;
  }

  public function
  rb_id2str(id:int):RString
  {
    var str:RString = global_symbols__id_str[id];
    if (str.klass == null) {
      str.klass = rb_cString;
    }
    return str;
  }

  public function
  is_notop_id(id:int):Boolean
  {
    return id > Id.tLAST_TOKEN;
  }

  public function
  is_local_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_LOCAL);
  }

  public function
  is_global_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_GLOBAL);
  }

  public function
  is_instance_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_INSTANCE);
  }

  public function
  is_attrset_id(id):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_ATTRSET);
  }

  public function
  is_const_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_CONST);
  }

  public function
  is_class_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_CLASS);
  }

  public function
  is_junk_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id.ID_SCOPE_MASK) == Id.ID_JUNK);
  }

  public function
  rb_is_const_id(id:int):Boolean
  {
    if (is_const_id(id)) {
      return true;
    } else {
      return false;
    }
  }


