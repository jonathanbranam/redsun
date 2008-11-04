package ruby.internals
{
import flash.utils.Dictionary;

public class Parse_y
{
  public var rc:RubyCore;

  protected var global_symbols:Symbols;

  protected var op_tbl:Array = [
    new OpTbl(Id_c.tDOT2,       ".."),
    new OpTbl(Id_c.tDOT3,       ".."),
    new OpTbl("+".charCodeAt(), "+(binary)"),
    new OpTbl("-".charCodeAt(), "-(binary)"),
    new OpTbl(Id_c.tPOW,        "**"),
    new OpTbl(Id_c.tUPLUS,      "+@"),
    new OpTbl(Id_c.tUMINUS,     "-@"),
    new OpTbl(Id_c.tCMP,        "<=>"),
    new OpTbl(Id_c.tGEQ,        ">="),
    new OpTbl(Id_c.tLEQ,        "<="),
    new OpTbl(Id_c.tEQ,         "=="),
    new OpTbl(Id_c.tEQQ,        "==="),
    new OpTbl(Id_c.tNEQ,        "!="),
    new OpTbl(Id_c.tMATCH,      "=~"),
    new OpTbl(Id_c.tNMATCH,     "!~"),
    new OpTbl(Id_c.tAREF,       "[]"),
    new OpTbl(Id_c.tASET,       "[]="),
    new OpTbl(Id_c.tLSHFT,      "<<"),
    new OpTbl(Id_c.tRSHFT,      ">>"),
    new OpTbl(Id_c.tCOLON2,     "::"),
  ];
  protected var op_tbl_count:int = op_tbl.length;

  public function
  rb_intern_str(str:Value):int
  {
    var enc:String;
    var id:int;

    // deal with encoding

    id = rc.parse_y.rb_intern3(rc.RSTRING_PTR(str), enc);
    return id;
  }

  // encoding.h:142
  public function
  rb_enc_isascii(c:int, enc:String):Boolean
  {
    // only support ASCII
    return true;
  }

  // encoding.h:146
  public function
  rb_enc_ispunct(c:int, enc:String):Boolean
  {
    // only support ascii
    return rb_ispunct(c);
  }

  public function
  rb_usascii_encoding():String
  {
    return "ASCII";
  }

  public function
  rb_intern3(name:String, enc:String):int
  {
    var id:int;

    if (global_symbols.sym_id[name] != undefined) {
      return global_symbols.sym_id[name];
    }

    var m:int = 0;
    var len:int = name.length;
    var c:int;
    var c_str:String;
    var skip_new_id:Boolean = false;

    switch (name.charAt()) {
      case "$":
        id |= Id_c.ID_GLOBAL;
        m++;
        // handle special global
        break;
      case "@":
        if (name.charAt(1) == "@") {
          id |= Id_c.ID_CLASS;
          m++;
        } else {
          id |= Id_c.ID_INSTANCE;
        }
        m++;
        break;
      default:
        c = name.charCodeAt(0);
        var op_handled:Boolean = false;
        if (c != "_".charCodeAt() && rb_enc_isascii(c, enc) && rb_enc_ispunct(c, enc)) {
          // operators
          var i:int;

          if (len == 1) {
            id = c;
            // goto id_register;
            skip_new_id = true;
            op_handled = true;
            break;
          }
          for (i = 0; i < op_tbl_count; i++) {
            if (OpTbl(op_tbl[i]).name == name) {
              id = OpTbl(op_tbl[i]).token;
              // goto id_register;
              skip_new_id = true;
              op_handled = true;
              break;
            }
          }
        }
        if (op_handled) break;

        if (name.charAt(len-1) == "=") {
          // attribute assignment
          id = rc.parse_y.rb_intern3(name.substr(0, len-1), enc);
          if (id > Id_c.tLAST_TOKEN && !is_attrset_id(id)) {
            // TODO: @skipped encoding
            //enc = rb_enc_get(rb_id2str(id));
            id = rb_id_attrset(id);
            // goto id_register;
            skip_new_id = true;
            break;
          }
        }
        else if (rb_enc_isupper(name.charAt(), enc)) {
          id = Id_c.ID_CONST;
        }
        else {
          id = Id_c.ID_LOCAL;
        }
        break;
    }

    // new_id:
    if (!skip_new_id) {
      global_symbols.last_id++;
      id |= (global_symbols.last_id << Id_c.ID_SCOPE_SHIFT);
    }

    // id_register:
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
    id &= ~Id_c.ID_SCOPE_MASK;
    id |= Id_c.ID_ATTRSET;
    return id;
  }

  public function
  register_symid(id:int, name:String, enc:String):int
  {
    var str:Value = rc.string_c.rb_enc_str_new(name, enc);
    rc.OBJ_FREEZE(str);
    global_symbols.sym_id[name] = id;
    global_symbols.id_str[id] = str;
    return id;
  }

  public function
  rb_intern2(name:String):int
  {
    return rc.parse_y.rb_intern3(name, rb_usascii_encoding());
  }

  public function
  rb_intern(name:String):int
  {
    return rc.parse_y.rb_intern2(name);
  }

  public function
  rb_intern_const(name:String):int
  {
    return rc.parse_y.rb_intern(name);
  }

  public function
  rb_id2name(id:int):String
  {
    var str:RString = rb_id2str(id);
    return str.string;
  }

  public function
  rb_ispunct(c:int):Boolean
  {
    return c < "A".charCodeAt() ||
           (c > "Z".charCodeAt() && c < "a".charCodeAt());
  }

  public function
  rb_id2str(id:int):RString
  {
    var str:RString;
    if (id < Id_c.tLAST_TOKEN) {
      var i:int = 0;

      if (rb_ispunct(id)) {
        i = id;
        str = global_symbols.op_sym[i];
        if (!str) {
          var name:String = String.fromCharCode(id);
          str = rc.string_c.rb_usascii_str_new2(name);
          rc.OBJ_FREEZE(str);
          global_symbols.op_sym[i] = str;
        }
        return str;
      }
      for (i = 0; i < op_tbl_count; i++) {
        if (OpTbl(op_tbl[i]).token == id) {
          var entry:OpTbl = op_tbl[i];
          str = global_symbols.op_sym[i];
          if (!str) {
            str = rc.string_c.rb_usascii_str_new2(entry.name);
            rc.OBJ_FREEZE(str);
            global_symbols.op_sym[i] = str;
          }
          return str;
        }
      }
    }
    if (global_symbols.id_str[id] != undefined) {
      str = global_symbols.id_str[id];
      if (str.klass == null) {
        str.klass = rc.string_c.rb_cString;
      }
      return str;
    }

    if (is_attrset_id(id)) {
      var id2:int = (id & ~Id_c.ID_SCOPE_MASK) | Id_c.ID_LOCAL;

      while (!(str = rb_id2str(id2))) {
        if (!is_local_id(id2)) return null;
        id2 = (id & ~Id_c.ID_SCOPE_MASK) | Id_c.ID_CONST;
      }
      str = rc.string_c.rb_str_dup(str);
      rc.string_c.rb_str_cat2(str, "=");
      rb_intern_str(str);
      if (global_symbols.id_str[id] != undefined) {
        str = global_symbols.id_str[id];
        if (str.klass == null) {
          str.klass = rc.string_c.rb_cString;
        }
        return str;
      }
    }

    rc.error_c.rb_bug("failed id lookup");
    return null;
  }

  public function
  is_notop_id(id:int):Boolean
  {
    return id > Id_c.tLAST_TOKEN;
  }

  public function
  is_local_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_LOCAL);
  }

  public function
  is_global_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_GLOBAL);
  }

  public function
  is_instance_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_INSTANCE);
  }

  public function
  is_attrset_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_ATTRSET);
  }

  public function
  is_const_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_CONST);
  }

  public function
  is_class_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_CLASS);
  }

  public function
  is_junk_id(id:int):Boolean
  {
    return is_notop_id(id) && ((id & Id_c.ID_SCOPE_MASK) == Id_c.ID_JUNK);
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

  // parse.y:9302
  public function
  rb_is_local_id(id:int):Boolean
  {
    if (is_local_id(id)) return true;
    return false;
  }

  public function
  Init_sym():void
  {
    global_symbols = new Symbols();
    global_symbols.sym_id = new Dictionary();
    global_symbols.id_str = new Dictionary();

    rc.id_c.Init_id();
  }

}
}
  import flash.utils.Dictionary;
  import ruby.internals.Id_c;


class Symbols
{
  public var last_id:int = Id_c.tLAST_ID;
  public var sym_id:Dictionary;
  public var id_str:Dictionary;
  public var ivar2_id:Dictionary;
  public var id_ivar2:Dictionary;

  public var op_sym:Array = new Array(Id_c.tLAST_TOKEN);


}

class OpTbl
{
  public var token:int;
  public var name:String;
  public function OpTbl(token:int=-1, name:String=null)
  {
    this.token = token;
    this.name = name;
  }
}
