package ruby.internals
{
public class RbVm
{
  public static const RUBY_VM_THREAD_STACK_SIZE:int = 128*1024;

  public static const VM_FRAME_MAGIC_METHOD:uint = 0x11;
  public static const VM_FRAME_MAGIC_BLOCK:uint  = 0x21;
  public static const VM_FRAME_MAGIC_CLASS:uint  = 0x31;
  public static const VM_FRAME_MAGIC_TOP:uint    = 0x41;
  public static const VM_FRAME_MAGIC_FINISH:uint = 0x51;
  public static const VM_FRAME_MAGIC_CFUNC:uint  = 0x61;
  public static const VM_FRAME_MAGIC_PROC:uint   = 0x71;
  public static const VM_FRAME_MAGIC_IFUNC:uint  = 0x81;
  public static const VM_FRAME_MAGIC_EVAL:uint   = 0x91;
  public static const VM_FRAME_MAGIC_LAMBDA:uint = 0xa1;
  public static const VM_FRAME_MAGIC_MASK_BITS:uint = 8;
  public static const VM_FRAME_MAGIC_MASK:uint    = (~(~0<<VM_FRAME_MAGIC_MASK_BITS));

  public static const ISEQ_TYPE_TOP:uint     = 1;
  public static const ISEQ_TYPE_METHOD:uint  = 2;
  public static const ISEQ_TYPE_BLOCK:uint   = 3;
  public static const ISEQ_TYPE_CLASS:uint   = 4;
  public static const ISEQ_TYPE_RESCUE:uint  = 5;
  public static const ISEQ_TYPE_ENSURE:uint  = 6;
  public static const ISEQ_TYPE_EVAL:uint    = 7;
  public static const ISEQ_TYPE_DEFINED_GUARD:uint = 8;

  public var running_thread:RbThread;
  public var src_encoding_index:int;

  public function RbVm()
  {
  }

}
}
