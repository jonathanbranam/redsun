package ruby.internals
{
public class RbBlock extends Value
{
  public var self:Value;    // share with method frame if it's only block
  public var lfp:StackPointer;     // share with method frame if it's only block
  public var dfp:StackPointer;     // share with method frame if it's only block
  public var block_iseq:Value;
  public var proc:Value;

  public function RbBlock()
  {
  }

}
}
