package ruby.internals
{
  import flash.utils.Dictionary;

public class RbVm
{
  public static const RUBY_VM_THREAD_STACK_SIZE:int = 128*1024;

  public static const VM_CALL_ARGS_SPLAT_BIT:uint    = (0x01 << 1);
  public static const VM_CALL_ARGS_BLOCKARG_BIT:uint = (0x01 << 2);
  public static const VM_CALL_FCALL_BIT:uint         = (0x01 << 3);
  public static const VM_CALL_VCALL_BIT:uint         = (0x01 << 4);
  public static const VM_CALL_TAILCALL_BIT:uint      = (0x01 << 5);
  public static const VM_CALL_TAILRECURSION_BIT:uint = (0x01 << 6);
  public static const VM_CALL_SUPER_BIT:uint         = (0x01 << 7);
  public static const VM_CALL_SEND_BIT:uint          = (0x01 << 8);

  public static const VM_SPECIAL_OBJECT_VMCORE:uint = 0x01;
  public static const VM_SPECIAL_OBJECT_CBASE:uint  = 0x02;

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

  public static const VM_FRAME_FLAG_PASSED:uint =  0x0100;

  public static const ISEQ_TYPE_TOP:uint     = 1;
  public static const ISEQ_TYPE_METHOD:uint  = 2;
  public static const ISEQ_TYPE_BLOCK:uint   = 3;
  public static const ISEQ_TYPE_CLASS:uint   = 4;
  public static const ISEQ_TYPE_RESCUE:uint  = 5;
  public static const ISEQ_TYPE_ENSURE:uint  = 6;
  public static const ISEQ_TYPE_EVAL:uint    = 7;
  public static const ISEQ_TYPE_DEFINED_GUARD:uint = 8;

  public static const BOP_PLUS:uint          =    0x01;
  public static const BOP_MINUS:uint         =    0x02;
  public static const BOP_MULT:uint          =    0x04;
  public static const BOP_DIV:uint           =    0x08;
  public static const BOP_MOD:uint           =    0x10;
  public static const BOP_EQ:uint            =    0x20;
  public static const BOP_LT:uint            =    0x40;
  public static const BOP_LE:uint            =    0x80;
  public static const BOP_LTLT:uint          =   0x100;
  public static const BOP_AREF:uint          =   0x200;
  public static const BOP_ASET:uint          =   0x400;
  public static const BOP_LENGTH:uint        =   0x800;
  public static const BOP_SUCC:uint          =  0x1000;
  public static const BOP_GT:uint            =  0x2000;
  public static const BOP_GE:uint            =  0x4000;
  public static const BOP_NOT:uint           =  0x8000;
  public static const BOP_NEQ:uint           = 0x10000;

  public var self:Value;

  public var global_vm_lock:*;

  public var main_thread:RbThread;
  public var running_thread:RbThread;

  public var living_threads:Dictionary;
  public var thgroup_default:Value;

  public var running:Boolean;
  public var thread_abort_on_exception:Boolean;

  public var trace_flag:uint;
  public var sleeper:int;

  public var mark_object_ary:Value;

  public var special_exceptions:Array;

  public var top_self:Value;
  public var load_path:Value;
  public var loaded_features:Value;
  public var loading_table:Object;

  public var signal_buf:Array;
  public var buffered_signal_size:uint;

  public var event_hooks:Array;

  public var src_encoding_index:int;

  public var verbose:Value;
  public var debug:Value;
  public var progname:Value;
  public var coverages:Value;

  // if defined(ENABLE_VM_OBJSPACE) && ENABLE_VM_OBJSPACE
  public var objspace:*;

  public function RbVm()
  {
  }

}
}
