package ruby.internals
{
public class Node extends Value
{
  public static const NODE_METHOD:uint = 1;
  public static const NODE_FBODY:uint = 2;
  public static const NODE_CFUNC:uint = 3;
  public static const NODE_SCOPE:uint = 4;
  public static const NODE_BLOCK:uint = 5;
  public static const NODE_IF:uint = 6;
  public static const NODE_CASE:uint = 7;
  public static const NODE_WHEN:uint = 8;
  public static const NODE_OPT_N:uint = 9;
  public static const NODE_WHILE:uint = 10;
  public static const NODE_UNTIL:uint = 11;
  public static const NODE_ITER:uint = 12;
  public static const NODE_FOR:uint = 13;
  public static const NODE_BREAK:uint = 14;
  public static const NODE_NEXT:uint = 15;
  public static const NODE_REDO:uint = 16;
  public static const NODE_RETRY:uint = 17;
  public static const NODE_BEGIN:uint = 18;
  public static const NODE_RESCUE:uint = 19;
  public static const NODE_RESBODY:uint = 20;
  public static const NODE_ENSURE:uint = 21;
  public static const NODE_AND:uint = 22;
  public static const NODE_OR:uint = 23;
  public static const NODE_MASGN:uint = 24;
  public static const NODE_LASGN:uint = 25;
  public static const NODE_DASGN:uint = 26;
  public static const NODE_DASGN_CURR:uint = 27;
  public static const NODE_GASGN:uint = 28;
  public static const NODE_IASGN:uint = 29;
  public static const NODE_IASGN2:uint = 30;
  public static const NODE_CDECL:uint = 31;
  public static const NODE_CVASGN:uint = 32;
  public static const NODE_CVDECL:uint = 33;
  public static const NODE_OP_ASGN1:uint = 34;
  public static const NODE_OP_ASGN2:uint = 35;
  public static const NODE_OP_ASGN_AND:uint = 36;
  public static const NODE_OP_ASGN_OR:uint = 37;
  public static const NODE_CALL:uint = 38;
  public static const NODE_FCALL:uint = 39;
  public static const NODE_VCALL:uint = 40;
  public static const NODE_SUPER:uint = 41;
  public static const NODE_ZSUPER:uint = 42;
  public static const NODE_ARRAY:uint = 43;
  public static const NODE_ZARRAY:uint = 44;
  public static const NODE_VALUES:uint = 45;
  public static const NODE_HASH:uint = 46;
  public static const NODE_RETURN:uint = 47;
  public static const NODE_YIELD:uint = 48;
  public static const NODE_LVAR:uint = 49;
  public static const NODE_DVAR:uint = 50;
  public static const NODE_GVAR:uint = 51;
  public static const NODE_IVAR:uint = 52;
  public static const NODE_CONST:uint = 53;
  public static const NODE_CVAR:uint = 54;
  public static const NODE_NTH_REF:uint = 55;
  public static const NODE_BACK_REF:uint = 56;
  public static const NODE_MATCH:uint = 57;
  public static const NODE_MATCH2:uint = 58;
  public static const NODE_MATCH3:uint = 59;
  public static const NODE_LIT:uint = 60;
  public static const NODE_STR:uint = 61;
  public static const NODE_DSTR:uint = 62;
  public static const NODE_XSTR:uint = 63;
  public static const NODE_DXSTR:uint = 64;
  public static const NODE_EVSTR:uint = 65;
  public static const NODE_DREGX:uint = 66;
  public static const NODE_DREGX_ONCE:uint = 67;
  public static const NODE_ARGS:uint = 68;
  public static const NODE_ARGS_AUX:uint = 69;
  public static const NODE_OPT_ARG:uint = 70;
  public static const NODE_POSTARG:uint = 71;
  public static const NODE_ARGSCAT:uint = 72;
  public static const NODE_ARGSPUSH:uint = 73;
  public static const NODE_SPLAT:uint = 74;
  public static const NODE_TO_ARY:uint = 75;
  public static const NODE_BLOCK_ARG:uint = 76;
  public static const NODE_BLOCK_PASS:uint = 77;
  public static const NODE_DEFN:uint = 78;
  public static const NODE_DEFS:uint = 79;
  public static const NODE_ALIAS:uint = 80;
  public static const NODE_VALIAS:uint = 81;
  public static const NODE_UNDEF:uint = 82;
  public static const NODE_CLASS:uint = 83;
  public static const NODE_MODULE:uint = 84;
  public static const NODE_SCLASS:uint = 85;
  public static const NODE_COLON2:uint = 86;
  public static const NODE_COLON3:uint = 87;
  public static const NODE_DOT2:uint = 88;
  public static const NODE_DOT3:uint = 89;
  public static const NODE_FLIP2:uint = 90;
  public static const NODE_FLIP3:uint = 91;
  public static const NODE_ATTRSET:uint = 92;
  public static const NODE_SELF:uint = 93;
  public static const NODE_NIL:uint = 94;
  public static const NODE_TRUE:uint = 95;
  public static const NODE_FALSE:uint = 96;
  public static const NODE_ERRINFO:uint = 97;
  public static const NODE_DEFINED:uint = 98;
  public static const NODE_POSTEXE:uint = 99;
  public static const NODE_ALLOCA:uint = 100;
  public static const NODE_BMETHOD:uint = 101;
  public static const NODE_MEMO:uint = 102;
  public static const NODE_IFUNC:uint = 103;
  public static const NODE_DSYM:uint = 104;
  public static const NODE_ATTRASGN:uint = 105;
  public static const NODE_PRELUDE:uint = 106;
  public static const NODE_LAMBDA:uint = 107;
  public static const NODE_OPTBLOCK:uint = 108;
  public static const NODE_LAST:uint = 109;

  public static const NOEX_PUBLIC:uint     = 0x00;
  public static const NOEX_NOSUPER:uint    = 0x01;
  public static const NOEX_PRIVATE:uint    = 0x02;
  public static const NOEX_PROTECTED:uint  = 0x04;
  public static const NOEX_MASK:uint       = 0x06;
  public static const NOEX_BASIC:uint      = 0x08;

  public static const NOEX_UNDEF:uint      = NOEX_NOSUPER;

  public static const NOEX_MODFUNC:uint    = 0x10;
  public static const NOEX_SUPER:uint      = 0x20;
  public static const NOEX_VCALL:uint      = 0x40;

  public static const NODE_TYPESHIFT:uint = 8;
  public static const NODE_TYPEMASK:uint = 0X7F<<NODE_TYPESHIFT;

  public static const NODE_LSHIFT:uint = NODE_TYPESHIFT+7;
  public static const CHAR_BIT:uint = 8;
  public static const NODE_LMASK:uint = ((1<< (4*CHAR_BIT-NODE_LSHIFT))-1);

  public static const CALL_PUBLIC:uint = 0;
  public static const CALL_FCALL:uint = 1;
  public static const CALL_VCALL:uint = 2;
  public static const CALL_SUPER:uint = 3;

  public static const RUBY_VM_METHOD_NODE:uint = NODE_METHOD;

  public var nd_file:String;

  public var u1:*;
  public var u2:*;
  public var u3:*;

  public function Node()
  {
  }

  public function nd_type():uint {
    return (flags & NODE_TYPEMASK) >> NODE_TYPESHIFT
  }

  public function nd_set_type(type:uint):void {
    flags = (flags & ~NODE_TYPEMASK) | ( (type << NODE_TYPESHIFT) & NODE_TYPEMASK )
  }

  public function get nd_noex():int { return u3; }
  public function set nd_noex(v:int):void { u3 = v; }

  public function get nd_clss():RClass { return u1; }
  public function set nd_clss(v:RClass):void { u1 = v; }

  public function get nd_head():Node { return u1; }
  public function get nd_alen():int  { return u2; }
  public function get nd_next():Node { return u3; }
  public function set nd_next(v:Node):void { u3 = v; }

  public function get nd_cond():Node { return u1; }
  public function get nd_body():Node { return u2; }
  public function get nd_else():Node { return u3; }

  public function get nd_orig():Value { return u3; }

  public function get nd_resq():Node { return u1; }
  public function get nd_ensr():Node { return u2; }

  public function get nd_1st():Node { return u1; }
  public function get nd_2nd():Node { return u2; }

  public function get nd_stts():Node { return u1; }

  public function get nd_oid():int { return u1; }
  public function get nd_cnt():int { return u2; }
  public function get nd_tbl():Array { return u3; }

  public function get nd_recv():Node { return u1; }
  public function get nd_mid():int   { return u2; }
  public function get nd_args():Node { return u3; }

  public function get nd_cfnc():Function { return u1; }
  public function get nd_argc():int { return u2; }

  public function get nd_visi():int { return u2; }
  public function set nd_visi(v:int):void { u2 = v; }

}
}
