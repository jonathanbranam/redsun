package ruby.internals
{
  import flash.utils.Dictionary;

public class RHash extends RBasic
{

  public var ntbl:Dictionary;
  public var iter_lev:int;
  public var ifnone:Value;

  public function RHash(klass:RClass=null)
  {
    super(klass);
    this.flags = Value.T_HASH;
  }

}
}
