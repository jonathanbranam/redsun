package ruby.internals
{
public class RClass
{
  public var name:String = null;
  public var rbasic:RBasic = new RBasic();

  public var iv_tbl:Object = {};
  public var m_tbl:Object = {};
  public var super_class:RClass = null;

  public function RClass(name:String = null, super_class:RClass = null)
  {
    this.name = name;
    this.super_class = super_class;
  }

}
}
