package ruby.internals
{
public class RSymbol extends Value
{
  public var id:int;

  public function RSymbol()
  {
    super();
    this.flags = Value.T_SYMBOL;
  }

}
}
