package ruby.internals
{
public class RBasic extends Value
{
  public var klass:RClass;

  public function RBasic(klass:RClass=null)
  {
    super();
    this.klass = klass;
  }

}
}
