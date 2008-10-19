package ruby.internals
{
import ruby.RObject;

/**
 * Should be RModule probably.
 */
public dynamic class RClass extends RObject
{
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
  public static const FL_USER10:uint      = 1 << (FL_USHIFT+10);
  public static const FL_USER11:uint      = 1 << (FL_USHIFT+11);
  public static const FL_USER12:uint      = 1 << (FL_USHIFT+12);
  public static const FL_USER13:uint      = 1 << (FL_USHIFT+13);
  public static const FL_USER14:uint      = 1 << (FL_USHIFT+14);
  public static const FL_USER15:uint      = 1 << (FL_USHIFT+15);
  public static const FL_USER16:uint      = 1 << (FL_USHIFT+16);
  public static const FL_USER17:uint      = 1 << (FL_USHIFT+17);
  public static const FL_USER18:uint      = 1 << (FL_USHIFT+18);
  public static const FL_USER19:uint      = 1 << (FL_USHIFT+19);

  public static const FL_SINGLETON:uint = FL_USER0;
  public static const FL_MARK:uint      = 1 << 5;
  public static const FL_RESERVED:uint  = 1 << 6;
  public static const FL_FINALIZE:uint  = 1 << 7;
  public static const FL_TAINT:uint     = 1 << 8;
  public static const FL_UNTRUSTED:uint = 1 << 9;
  public static const FL_EXIVAR:uint    = 1 << 10;
  public static const FL_FREEZE:uint    = 1 << 11;

  public static const FL_USHIFT:uint      = 12;

  public var name:String = null;
  //public var rbasic:RBasic = new RBasic();

  //public var iv_tbl:Object = {};
  public var m_tbl:Object = {};
  public var super_class:RClass = null;

  public function RClass(name:String = null, super_class:RClass = null, klass:RClass=null)
  {
    super(klass);
    this.name = name;
    this.super_class = super_class;
    this.flags = Value.T_CLASS;
  }

  public function is_singleton():Boolean {
    return (flags & FL_SINGLETON) != 0
  }


}
}

