package ruby.internals
{
public class Node extends Value
{
  public static const NODE_METHOD:uint = 1;
  public static const NODE_FBODY:uint = 1;
  public static const NODE_CFUNC:uint = 1;
  public static const NODE_SCOPE:uint = 1;
  public static const NODE_BLOCK:uint = 1;
  public static const NODE_IF:uint = 1;
  public static const NODE_CASE:uint = 1;
  public static const NODE_WHEN:uint = 1;
  public static const NODE_OPT_N:uint = 1;
  public static const NODE_WHILE:uint = 1;
  public static const NODE_UNTIL:uint = 1;
  public static const NODE_ITER:uint = 1;
  public static const NODE_FOR:uint = 1;
  public static const NODE_BREAK:uint = 1;
  public static const NODE_NEXT:uint = 1;
  public static const NODE_REDO:uint = 1;
  public static const NODE_RETRY:uint = 1;
  public static const NODE_BEGIN:uint = 1;
  public static const NODE_RESCUE:uint = 1;
  public static const NODE_RESBODY:uint = 1;
  public static const NODE_ENSURE:uint = 1;
  public static const NODE_AND:uint = 1;
  public static const NODE_OR:uint = 1;
  public static const NODE_MASGN:uint = 1;
  public static const NODE_LASGN:uint = 1;
  public static const NODE_DASGN:uint = 1;
  public static const NODE_DASGN_CURR:uint = 1;
  public static const NODE_GASGN:uint = 1;
  public static const NODE_IASGN:uint = 1;
  public static const NODE_IASGN2:uint = 1;
  public static const NODE_CDECL:uint = 1;
  public static const NODE_CVASGN:uint = 1;
  public static const NODE_CVDECL:uint = 1;
  public static const NODE_OP_ASGN1:uint = 1;
  public static const NODE_OP_ASGN2:uint = 1;
  public static const NODE_OP_ASGN_AND:uint = 1;
  public static const NODE_OP_ASGN_OR:uint = 1;
  public static const NODE_CALL:uint = 1;
  public static const NODE_FCALL:uint = 1;
  public static const NODE_VCALL:uint = 1;
  public static const NODE_SUPER:uint = 1;
  public static const NODE_ZSUPER:uint = 1;
  public static const NODE_ARRAY:uint = 1;
  public static const NODE_ZARRAY:uint = 1;
  public static const NODE_VALUES:uint = 1;
  public static const NODE_HASH:uint = 1;
  public static const NODE_RETURN:uint = 1;
  public static const NODE_YIELD:uint = 1;
  public static const NODE_LVAR:uint = 1;
  public static const NODE_DVAR:uint = 1;
  public static const NODE_GVAR:uint = 1;
  public static const NODE_IVAR:uint = 1;
  public static const NODE_CONST:uint = 1;
  public static const NODE_CVAR:uint = 1;
  public static const NODE_NTH_REF:uint = 1;
  public static const NODE_BACK_REF:uint = 1;
  public static const NODE_MATCH:uint = 1;
  public static const NODE_MATCH2:uint = 1;
  public static const NODE_MATCH3:uint = 1;
  public static const NODE_LIT:uint = 1;
  public static const NODE_STR:uint = 1;
  public static const NODE_DSTR:uint = 1;
  public static const NODE_XSTR:uint = 1;
  public static const NODE_DXSTR:uint = 1;
  public static const NODE_EVSTR:uint = 1;
  public static const NODE_DREGX:uint = 1;
  public static const NODE_DREGX_ONCE:uint = 1;
  public static const NODE_ARGS:uint = 1;
  public static const NODE_ARGS_AUX:uint = 1;
  public static const NODE_OPT_ARG:uint = 1;
  public static const NODE_POSTARG:uint = 1;
  public static const NODE_ARGSCAT:uint = 1;
  public static const NODE_ARGSPUSH:uint = 1;
  public static const NODE_SPLAT:uint = 1;
  public static const NODE_TO_ARY:uint = 1;
  public static const NODE_BLOCK_ARG:uint = 1;
  public static const NODE_BLOCK_PASS:uint = 1;
  public static const NODE_DEFN:uint = 1;
  public static const NODE_DEFS:uint = 1;
  public static const NODE_ALIAS:uint = 1;
  public static const NODE_VALIAS:uint = 1;
  public static const NODE_UNDEF:uint = 1;
  public static const NODE_CLASS:uint = 1;
  public static const NODE_MODULE:uint = 1;
  public static const NODE_SCLASS:uint = 1;
  public static const NODE_COLON2:uint = 1;
  public static const NODE_COLON3:uint = 1;
  public static const NODE_DOT2:uint = 1;
  public static const NODE_DOT3:uint = 1;
  public static const NODE_FLIP2:uint = 1;
  public static const NODE_FLIP3:uint = 1;
  public static const NODE_ATTRSET:uint = 1;
  public static const NODE_SELF:uint = 1;
  public static const NODE_NIL:uint = 1;
  public static const NODE_TRUE:uint = 1;
  public static const NODE_FALSE:uint = 1;
  public static const NODE_ERRINFO:uint = 1;
  public static const NODE_DEFINED:uint = 1;
  public static const NODE_POSTEXE:uint = 1;
  public static const NODE_ALLOCA:uint = 1;
  public static const NODE_BMETHOD:uint = 1;
  public static const NODE_MEMO:uint = 1;
  public static const NODE_IFUNC:uint = 1;
  public static const NODE_DSYM:uint = 1;
  public static const NODE_ATTRASGN:uint = 1;
  public static const NODE_PRELUDE:uint = 1;
  public static const NODE_LAMBDA:uint = 1;
  public static const NODE_OPTBLOCK:uint = 1;
  public static const NODE_LAST:uint = 1;

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
    flags = ( (flags & ~(-1 << NODE_LSHIFT) ) | ( (type & NODE_LMASK) << NODE_LSHIFT) )
  }

  public function nd_noex():int {
    return u3;
  }

  public function nd_clss():RClass {
    return u1;
  }

  public function nd_body():Node {
    return u2;
  }

}
}
