package ruby.internals
{
public class RFloat extends RBasic
{
  public var float_value:Number;

  public function RFloat(klass:RClass=null, val:Number=NaN)
  {
    super(klass);
    this.flags = Value.T_FLOAT;
    this.float_value = val;
  }

}
}
