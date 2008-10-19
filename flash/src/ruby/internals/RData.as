package ruby.internals
{
public class RData extends RBasic
{

  public var data:*;
  public var dfree:Function;
  public var dmark:Function;

  public function RData(klass:RClass=null)
  {
    super(klass);
  }

}
}
