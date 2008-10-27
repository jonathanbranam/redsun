package ruby.internals
{
public class Value
{
  public var flags:uint;

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
