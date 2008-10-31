package ruby.internals
{

/**
 * Should be RModule probably.
 */
public dynamic class RClass extends RObject
{
  public var name:String = null;

  public var super_class:RClass = null;
  public var iv_tbl:Object = new Object();

  public var m_tbl:Object = new Object();

  public function RClass(name:String = null, super_class:RClass = null, klass:RClass=null)
  {
    super(klass);
    this.iv_index_tbl = new Object();
    this.name = name;
    this.super_class = super_class;
    this.flags = Value.T_CLASS;
  }

  public function is_singleton():Boolean {
    return (flags & FL_SINGLETON) != 0
  }


}
}

