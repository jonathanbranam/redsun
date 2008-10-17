package ruby.internals
{
import ruby.RObject;

/**
 * Should be RModule probably.
 */
public dynamic class RClass extends RObject
{
  public static const FL_SINGLETON:int = 1;

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
  }

  public function is_singleton():Boolean {
    return (flags & FL_SINGLETON) != 0
  }


}
}

