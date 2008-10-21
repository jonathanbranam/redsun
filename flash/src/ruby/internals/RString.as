package ruby.internals
{

public class RString extends RBasic
{
  public var string:String;

  public function RString(klass:RClass=null)
  {
    super(klass);
    this.flags = T_STRING;
  }

}
}
