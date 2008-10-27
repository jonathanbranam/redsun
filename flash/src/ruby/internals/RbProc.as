package ruby.internals
{
public class RbProc extends Value
{
  public var block:RbBlock;

  public var envval:Value // for GC mark
  public var blockprocval:Value;
  public var safe_level:int;
  public var is_from_method:Boolean;
  public var is_lambda:Boolean;

  public function RbProc()
  {
    super();
  }

}
}
