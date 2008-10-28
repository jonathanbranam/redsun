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
  public static const idLTLT:int = 300;
  public static const idLE:int = 301;
  public static const idGT:int = ">".charCodeAt();
  public static const idGE:int = 302;
  public static const idEq:int = 303;
  public static const idEqq:int = 304;
  public static const idNeq:int = 305;
  public static const idNot:int = "!".charCodeAt();
  public static const idBackquote:int = "`".charCodeAt();
  public static const idEqTilde:int = 306;
  public static const idAREF:int = 307;
  public static const idASET:int = 308;
  public static const tIntern:int = 309;
  public static const tMethodMissing:int = 310;
  public static const tLength:int = 311;
  public static const tGets:int = 312;
  public static const tSucc:int = 313;
  public static const tEach:int = 314;
  public static const tLambda:int = 315;
  public static const tSend:int = 316;
  public static const t__send__:int = 317;
  public static const tInitialize:int = 318;
  public static const tBitblt:int = 319;
  public static const tAnswer:int = 320;
  public static const tLAST_ID:int = 321;


  public var idInitialize:int;
  public var idMethodMissing:int;

  public static const tLAST_TOKEN:int = 400;
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
