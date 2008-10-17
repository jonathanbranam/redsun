package ruby
{
import ruby.internals.RClass;
import ruby.internals.Value;

public dynamic class RObject extends Value
{
  public var klass:RClass;
  public var iv_tbl:Object = {};

  public function RObject(klass:RClass=null)
  {
    this.klass = klass;
    this.flags = Value.T_OBJECT;
  }

}
}
