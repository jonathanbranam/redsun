package ruby.internals
{
public class RFloat extends RBasic
{
  public var float_value:Number;

  public function RFloat(klass:RClass=null, val:Number=NaN)
  {
    super(klass);
    this.float_value = val;
  }

}
}
