package ruby.internals
{
public class Id_c
{
  public var rc:RubyCore;

  import flash.utils.Dictionary;

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

  public var idInitialize:int;
  public var idMethodMissing:int;

  public static const tLAST_TOKEN:int = 255;
  public static const idLAST_TOKEN:int = tLAST_TOKEN >> ID_SCOPE_SHIFT;

  public var id_core_define_method:int;

  public function
  Init_id():void
  {
    // TODO: @skipped many ids
    id_core_define_method = rc.parse_y.rb_intern("core#define_method");

    // TODO: @fix This is actually defined based on parse.y yacc file
    idMethodMissing = rc.parse_y.rb_intern("method_missing");
    idInitialize = rc.parse_y.rb_intern("initialize");
  }

}
}
