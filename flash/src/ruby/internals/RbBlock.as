package ruby.internals
{
public class RbBlock extends Value
{
  public var self:Value;    // share with method frame if it's only block
  public var lfp:StackPointer;     // share with method frame if it's only block
  public var dfp:StackPointer;     // share with method frame if it's only block
  public var block_iseq:RbISeq;
  public var proc:Value;

  public function RbBlock(copy:RbBlock=null)
  {
    if (copy) {
      this.self = copy.self;
      this.lfp = copy.lfp.clone();
      this.dfp = copy.dfp.clone();
      this.block_iseq = copy.block_iseq;
      this.proc = copy.proc;
    }
  }

}
}
