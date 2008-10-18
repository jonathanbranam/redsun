package ruby.internals
{
public class RbControlFrame
{
  public var pc:Function;
  public var sp:Array;
  public var bp:Array;

  public var iseq:RbISeq;
  public var flag:uint;
  public var self:Value;
  public var lfp:Array;
  public var dfp:Array;

  public var block_iseq:RbISeq;
  public var proc:Value;
  public var method_id:int;
  public var method_class:Value;
  public var prof_time_self:Value;
  public var prof_time_child:Value;

  public function RbControlFrame()
  {
  }

}
}
