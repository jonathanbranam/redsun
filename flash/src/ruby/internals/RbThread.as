package ruby.internals
{
public class RbThread extends Value
{
  public static const THREAD_TO_KILL:uint = 0;
  public static const THREAD_RUNNABLE:uint = 1;
  public static const THREAD_STOPPED:uint = 2;
  public static const THREAD_STOPPED_FOREVER:uint = 3;
  public static const THREAD_KILLED:uint = 4;


  public var self:Value;

  public var vm:RbVm;

  public var stack:Array;

  public var stack_size:uint;

  public var cfp_stack:Array;

  public var cfp:RbControlFrame;

  public var safe_level:int;
  public var raised_flag:int;
  public var last_status:Value;

  public var state:int;

  public var passed_block:RbBlock;

  public var top_self:Value;
  public var top_wrapper:Value;

  public var base_block:RbBlock;

  public var local_lfp:Array;
  public var local_svar:Value;

  public var thread_id:*;
  public var status:*;
  public var priority:int;
  public var slice:int;

  public var native_thread_data:*;

  public var thgroup:Value;
  public var value:Value;

  public var errinfo:Value;
  public var thrown_errinfo:Value;
  public var exec_signal:int;

  public var interrupt_flag:int;
  public var interrupt_lock:*;
  public var unblock:*;
  public var locking_mutex:Value;
  public var keeping_mutexes:*;
  public var transition_for_lock:int;

  public var tag:*;
  public var trap_tag:*;

  public var parse_in_eval:int;
  public var mild_compile_error:int;

  public var local_storage:Object;

  public var join_list_next:RbThread;
  public var join_list_head:RbThread;

  public var first_proc:Value;
  public var first_args:Value;

  public var stat_insn_usage:Value;

  public var event_hook:*;
  public var event_flags:*;
  public var tracing:int;

  public var fiber:Value;
  public var root_fiber:Value;
  public var root_jmpbuf:*;

  public var method_missing_reason:int;
  public var abort_on_exception:int;


  public function RbThread()
  {
  }

}
}
