package ruby.internals
{
public class RArray extends RBasic
{
  public var array:Array;

  public function RArray(klass:RClass=null)
  {
    super(klass);
    this.flags = Value.T_ARRAY;
  }

}
}
