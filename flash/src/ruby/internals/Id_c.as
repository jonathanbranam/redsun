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

  public static const tLSHFT:int = 300;
  public static const tLEQ:int = 301;
  public static const tGEQ:int = 302;
  public static const tEQ:int = 303;
  public static const tEQQ:int = 304;
  public static const tNEQ:int = 305;
  public static const tMATCH:int = 306;
  public static const tAREF:int = 307;
  public static const tASET:int = 308;

  public static const tDOT2:int = 309;
  public static const tDOT3:int = 310;
  public static const tPOW:int = 311;
  public static const tUPLUS:int = 312;
  public static const tUMINUS:int = 313;
  public static const tCMP:int = 314;
  public static const tNMATCH:int = 315;
  public static const tRSHFT:int = 316;
  public static const tCOLON2:int = 317;

  public static const idPLUS:int = "+".charCodeAt();
  public static const idMINUS:int = "-".charCodeAt();
  public static const idMULT:int = "*".charCodeAt();
  public static const idDIV:int = "/".charCodeAt();
  public static const idMOD:int = "%".charCodeAt();
  public static const idLT:int = "<".charCodeAt();
  public static const idLTLT:int = tLSHFT;
  public static const idLE:int = tLEQ;
  public static const idGT:int = ">".charCodeAt();
  public static const idGE:int = tGEQ;
  public static const idEq:int = tEQ;
  public static const idEqq:int = tEQQ;
  public static const idNeq:int = tNEQ;
  public static const idNot:int = "!".charCodeAt();
  public static const idBackquote:int = "`".charCodeAt();
  public static const idEqTilde:int = tMATCH;
  public static const idAREF:int = tAREF;
  public static const idASET:int = tASET;
  public static const tIntern:int = 318;
  public static const tMethodMissing:int = 319;
  public static const tLength:int = 320;
  public static const tGets:int = 321;
  public static const tSucc:int = 322;
  public static const tEach:int = 323;
  public static const tLambda:int = 324;
  public static const tSend:int = 325;
  public static const t__send__:int = 326;
  public static const tInitialize:int = 327;
  public static const tBitblt:int = 328;
  public static const tAnswer:int = 329;
  public static const tLAST_ID:int = 330;


  public var idInitialize:int;
  public var idMethodMissing:int;

  public static const tLAST_TOKEN:int = 400;
  public static const idLAST_TOKEN:int = tLAST_TOKEN >> ID_SCOPE_SHIFT;

  public var id_core_set_method_alias:int;
  public var id_core_set_variable_alias:int;
  public var id_core_undef_method:int;
  public var id_core_define_method:int;
  public var id_core_define_singleton_method:int;
  public var id_core_set_postexe:int;

  public function
  Init_id():void
  {
    // TODO: @skipped many ids
    id_core_set_method_alias = rc.parse_y.rb_intern("core#set_method_alias");
    id_core_set_variable_alias = rc.parse_y.rb_intern("core#set_variable_alias");
    id_core_undef_method = rc.parse_y.rb_intern("core#undef_method");
    id_core_define_method = rc.parse_y.rb_intern("core#define_method");
    id_core_define_singleton_method = rc.parse_y.rb_intern("core#define_singleton_method");
    id_core_set_postexe = rc.parse_y.rb_intern("core#set_postexe");

    // TODO: @fix This is actually defined based on parse.y yacc file
    idMethodMissing = rc.parse_y.rb_intern("method_missing");
    idInitialize = rc.parse_y.rb_intern("initialize");
  }

}
}
