package ruby.internals
{
public class Id
{
  public static const ID_SCOPE_SHIFT:uint = 3;
  public static const ID_SCOPE_MASK:uint  = 0x07;
  public static const ID_LOCAL:uint       = 0x00;
  public static const ID_INSTANCE:uint    = 0x01;
  public static const ID_GLOBAL:uint      = 0x03;
  public static const ID_ATTRSET:uint     = 0x04;
  public static const ID_CONST:uint       = 0x05;
  public static const ID_CLASS:uint       = 0x06;
  public static const ID_JUNK:uint        = 0x07;
  public static const ID_INTERNAL:uint    = ID_JUNK;

  public static const idPLUS:int = "+".charCodeAt();
  public static const idMINUS:int = "-".charCodeAt();
  public static const idMULT:int = "*".charCodeAt();
  public static const idDIV:int = "/".charCodeAt();
  public static const idMOD:int = "%".charCodeAt();
  public static const idLT:int = "<".charCodeAt();
  public static const idLTLT:int = 0;
  public static const idLE:int = 0;
  public static const idGT:int = ">".charCodeAt();
  public static const idGE:int = 0;

  public static const idNot:int = "!".charCodeAt();
  public static const idBackquote:int = "`".charCodeAt();

  public static const tLAST_TOKEN:int = 255;
  public static const idLAST_TOKEN:int = tLAST_TOKEN >> ID_SCOPE_SHIFT;

  public function Id()
  {
  }

  public function rb_usascii_encoding():String {
    return "ASCII";
  }

  protected var global_symbols__sym_id:Object = {};
  protected var global_symbols__id_str:Object = {};
  protected var global_symbols__last_id:int = tLAST_TOKEN;

  public function rb_intern3(name:String, enc:String):int {
    var id:int;

    if (global_symbols__sym_id[name] != undefined) {
      return global_symbols__sym_id[name];
    }

    var m:int = 0;

    switch (name.charAt()) {
    case "$":
      id |= ID_GLOBAL;
      m++;
      // handle special global
      break;
    case "@":
      if (name.charAt(1) == "@") {
        id |= ID_CLASS;
        m++;
      } else {
        id |= ID_INSTANCE;
      }
      m++;
      break;
    default:
      break;
    }

    global_symbols__last_id++;
    id |= (global_symbols__last_id << ID_SCOPE_SHIFT);

    return register_symid(id, name, enc);
  }

  public function register_symid(id:int, name:String, enc:String):int {
    global_symbols__sym_id[name] = id;
    global_symbols__id_str[id] = name;
    return id;
  }

  public function rb_intern2(name:String):int {
    return rb_intern3(name, rb_usascii_encoding());
  }

  public function rb_intern(name:String):int {
    return rb_intern2(name);
  }

  public function rb_id2name(id:int):String {
    return global_symbols__id_str[id];
  }

}
}
