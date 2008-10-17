package ruby
{
import ruby.internals.RBasic;
import ruby.internals.RClass;
import ruby.internals.Value;

public class RObject extends RBasic
{
  public var iv_tbl:Object = {};

  public function RObject(klass:RClass=null)
  {
    this.klass = klass;
    this.flags = Value.T_OBJECT;
  }

}
}
