package ruby.internals
{
public class RbControlFrame extends RbBlock
{
  public var pc_fn:Function;
  public var pc_ary:Array;
  public var pc_index:int;

  public var sp:StackPointer;
  public var bp:StackPointer;

  public var iseq:RbISeq;
  public var flag:uint;
  //public var self:Value;
  //public var lfp:Array;
  //public var dfp:Array;

  //public var block_iseq:RbISeq;
  //public var proc:Value;
  public var method_id:int;
  public var method_class:RClass;
  public var prof_time_self:Value;
  public var prof_time_child:Value;

  public function RbControlFrame()
  {
  }

  public function VM_FRAME_TYPE():uint {
    return flag & RbVm.VM_FRAME_MAGIC_MASK;
  }



}
}
