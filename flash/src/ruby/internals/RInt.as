package ruby.internals
{
public class RInt extends Value
{
  public var value:int;

  public function RInt(value:int=0)
  {
    super();
    this.flags = Value.T_FIXNUM;
    this.value = value;
  }

}
}
