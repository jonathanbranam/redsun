package ruby.internals
{
import ruby.internals.RBasic;
import ruby.internals.RClass;
import ruby.internals.Value;

public class RObject extends RBasic
{
  public var ivptr:Array;

  // Actual storage on a class, but just a pointer on an object
  public var iv_index_tbl:Object;

  public function RObject(klass:RClass=null)
  {
    super(klass);
    this.flags = Value.T_OBJECT;
  }

}
}
