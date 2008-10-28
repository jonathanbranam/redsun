package ruby.internals
{
public class Proc_c
{
  public var rc:RubyCore;

  import ruby.internals.RData;
  import ruby.internals.Value;

  // proc.c:73
  public function
  rb_obj_is_proc(proc:Value):Boolean
  {
    if (rc.TYPE(proc) == Value.T_DATA &&
        RData(proc).dfree == proc_free) {
        return true;
    }
    else {
      return false;
    }
  }

  // proc.c:35
  public function
  proc_free(ptr:*):void
  {
    rc.error_c.rb_bug("proc_free");
  }

}
}
