package ruby.internals
{
public class Value
{
  public var flags:uint;

  public static const FL_USER0:uint      = 1 << (FL_USHIFT+0);
  public static const FL_USER1:uint      = 1 << (FL_USHIFT+1);
  public static const FL_USER2:uint      = 1 << (FL_USHIFT+2);
  public static const FL_USER3:uint      = 1 << (FL_USHIFT+3);
  public static const FL_USER4:uint      = 1 << (FL_USHIFT+4);
  public static const FL_USER5:uint      = 1 << (FL_USHIFT+5);
  public static const FL_USER6:uint      = 1 << (FL_USHIFT+6);
  public static const FL_USER7:uint      = 1 << (FL_USHIFT+7);
  public static const FL_USER8:uint      = 1 << (FL_USHIFT+8);
  public static const FL_USER9:uint      = 1 << (FL_USHIFT+9);
  public static const FL_USER10:uint     = 1 << (FL_USHIFT+10);
  public static const FL_USER11:uint     = 1 << (FL_USHIFT+11);
  public static const FL_USER12:uint     = 1 << (FL_USHIFT+12);
  public static const FL_USER13:uint     = 1 << (FL_USHIFT+13);
  public static const FL_USER14:uint     = 1 << (FL_USHIFT+14);
  public static const FL_USER15:uint     = 1 << (FL_USHIFT+15);
  public static const FL_USER16:uint     = 1 << (FL_USHIFT+16);
  public static const FL_USER17:uint     = 1 << (FL_USHIFT+17);
  public static const FL_USER18:uint     = 1 << (FL_USHIFT+18);
  public static const FL_USER19:uint     = 1 << (FL_USHIFT+19);

  public static const FL_SINGLETON:uint = FL_USER0;
  public static const FL_MARK:uint      = 1 << 5;
  public static const FL_RESERVED:uint  = 1 << 6;
  public static const FL_FINALIZE:uint  = 1 << 7;
  public static const FL_TAINT:uint     = 1 << 8;
  public static const FL_UNTRUSTED:uint = 1 << 9;
  public static const FL_EXIVAR:uint    = 1 << 10;
  public static const FL_FREEZE:uint    = 1 << 11;

  public static const FL_USHIFT:uint    = 12;

  public static const ELTS_SHARED:uint  = FL_USER2;

  public static const RUBY_T_NONE:uint   = 0x00
  public static const RUBY_T_OBJECT:uint = 0x01;
  public static const RUBY_T_CLASS:uint  = 0x02;
  public static const RUBY_T_MODULE:uint = 0x03;
  public static const RUBY_T_FLOAT:uint  = 0x04;
  public static const RUBY_T_STRING:uint = 0x05;
  public static const RUBY_T_REGEXP:uint = 0x06;
  public static const RUBY_T_ARRAY:uint  = 0x07;
  public static const RUBY_T_HASH:uint   = 0x08;
  public static const RUBY_T_STRUCT:uint = 0x09;
  public static const RUBY_T_BIGNUM:uint = 0x0a;
  public static const RUBY_T_FILE:uint   = 0x0b;
  public static const RUBY_T_DATA:uint   = 0x0c;
  public static const RUBY_T_MATCH:uint  = 0x0d;
  public static const RUBY_T_COMPLEX:uint  = 0x0e;
  public static const RUBY_T_RATIONAL:uint = 0x0f;
  public static const RUBY_T_NIL:uint    = 0x11;
  public static const RUBY_T_TRUE:uint   = 0x12;
  public static const RUBY_T_FALSE:uint  = 0x13;
  public static const RUBY_T_SYMBOL:uint = 0x14;
  public static const RUBY_T_FIXNUM:uint = 0x15;
  public static const RUBY_T_UNDEF:uint  = 0x1b;
  public static const RUBY_T_NODE:uint   = 0x1c;
  public static const RUBY_T_ICLASS:uint = 0x1d;
  public static const RUBY_T_DEFERRED:uint = 0x1e;

  public static const RUBY_T_MASK:uint   = 0x1f;

  public static const T_NONE:uint =    RUBY_T_NONE;
  public static const T_NIL:uint =     RUBY_T_NIL;
  public static const T_OBJECT:uint =  RUBY_T_OBJECT;
  public static const T_CLASS:uint =   RUBY_T_CLASS;
  public static const T_ICLASS:uint =  RUBY_T_ICLASS;
  public static const T_MODULE:uint =  RUBY_T_MODULE;
  public static const T_FLOAT:uint =   RUBY_T_FLOAT;
  public static const T_STRING:uint =  RUBY_T_STRING;
  public static const T_REGEXP:uint =  RUBY_T_REGEXP;
  public static const T_ARRAY:uint =   RUBY_T_ARRAY;
  public static const T_HASH:uint =    RUBY_T_HASH;
  public static const T_STRUCT:uint =  RUBY_T_STRUCT;
  public static const T_BIGNUM:uint =  RUBY_T_BIGNUM;
  public static const T_FILE:uint =    RUBY_T_FILE;
  public static const T_FIXNUM:uint =  RUBY_T_FIXNUM;
  public static const T_TRUE:uint =    RUBY_T_TRUE;
  public static const T_FALSE:uint =   RUBY_T_FALSE;
  public static const T_DATA:uint =    RUBY_T_DATA;
  public static const T_MATCH:uint =   RUBY_T_MATCH;
  public static const T_SYMBOL:uint =  RUBY_T_SYMBOL;
  public static const T_RATIONAL:uint =  RUBY_T_RATIONAL;
  public static const T_COMPLEX:uint =  RUBY_T_COMPLEX;
  public static const T_UNDEF:uint =   RUBY_T_UNDEF;
  public static const T_NODE:uint =    RUBY_T_NODE;
  public static const T_DEFERRED:uint =  RUBY_T_DEFERRED;
  public static const T_MASK:uint =    RUBY_T_MASK;


  public function BUILTIN_TYPE():int {
    return flags & T_MASK;
  }


  public function Value()
  {
  }

  public function is_frozen():Boolean
  {
    return false;
  }

  public function is_string():Boolean {
    return BUILTIN_TYPE() == T_STRING;
  }

  public function is_module():Boolean {
    return BUILTIN_TYPE() == T_MODULE;
  }

  public function is_class():Boolean {
    return BUILTIN_TYPE() == T_CLASS;
  }

  public function is_include_class():Boolean {
    return BUILTIN_TYPE() == T_ICLASS;
  }

  public function get_type():uint {
    /*
    if (IMMEDIATE_P() {

    }*/
    return BUILTIN_TYPE();
  }

}
}
