package ruby.internals
{
public class RbEnv
{
  public var env:StackPointer;
  public var env_size:int;
  public var local_size:int;
  public var prev_envval:Value; // for GC mark
  public var block:RbBlock;

  public function RbEnv()
  {
    block = new RbBlock();
  }

}
}
