package ruby.internals
{
import flash.utils.Dictionary;

public class Parse_y
{
  protected var rc:RubyCore;
  public var string_c:String_c;

  public function Parse_y(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function
  rb_intern_str(str:Value):int
  {
    var enc:String;
    var id:int;

    // deal with encoding

    id = rb_intern3(rc.RSTRING_PTR(str), enc);
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
      break;
    }

    global_symbols__last_id++;
    id |= (global_symbols__last_id << Id.ID_SCOPE_SHIFT);

    return register_symid(id, name, enc);
  }

  public function
  register_symid(id:int, name:String, enc:String):int
  {
    var str:Value = rc.rb_enc_str_new(name, enc);
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
      str.klass = rc.rb_cString;
    }
    return str;
  }

  public function
  is_notop_id(id:int):Boolean
  {
    return id > Id.tLAST_TOKEN;
  }

  public function
  is_const_id(id:int):Boolean
  {
    return is_notop_id(id) && (id & Id.ID_SCOPE_MASK) == Id.ID_CONST;
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


}
}
