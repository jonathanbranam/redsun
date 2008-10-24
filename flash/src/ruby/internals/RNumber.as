package ruby.internals
{
public class RNumber extends Value
{
  public var value:Number;

  public function RNumber(value:Number=NaN)
  {
    super();
    this.value = value;
  }

  }
}
