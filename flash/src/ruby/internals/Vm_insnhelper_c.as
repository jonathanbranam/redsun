package ruby.internals
{
public class Vm_insnhelper_c
{
  protected var rc:RubyCore;

  public var error_c:Error_c;

  public function Vm_insnhelper_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function
  vm_get_cref(iseq:RbISeq, lfp:Array, dfp:Array):Node
  {
    var cref:Node = null;

    while (1) {
      if (lfp == dfp) {
        cref = iseq.cref_stack
        break;
      } else if (dfp[dfp.length-1] != rc.Qnil) {
        cref = dfp[dfp.length-1];
        break;
      }
      dfp = rc.GET_PREV_DFP(dfp);
    }

    if (cref == null) {
      error_c.rb_bug("vm_get_cref: unreachable");
    }

    return cref;
  }

}
}
