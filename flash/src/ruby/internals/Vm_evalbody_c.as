package ruby.internals
{
public class Vm_evalbody_c
{
  public var rc:RubyCore;

  import ruby.internals.RbControlFrame;
  import ruby.internals.RbThread;
  import ruby.internals.RubyFrame;
  import ruby.internals.Value;

  protected var inner_loop_depth:int = 0;

  // vm_evalbody.c:30
  public function
  vm_eval(th:RbThread, initial:Value):Value
  {
    var ret:Value;

    var frame:RubyFrame = new RubyFrame(rc, th);

    if (th.cfp.pc_fn != null) {
      th.cfp.pc_fn.call(this, frame);
    } else if (th.cfp.pc_ary != null) {
      vm_eval_array(th, initial, frame);
    } else {
      rc.error_c.rb_bug("no pc_fn or pc_ary in thread");
    }

    ret = th.cfp.sp.pop(); //pop

    // Just leave Qpause on the top of the stack?
    if (ret == rc.Qpause) {
      return rc.Qpause;
    }

    if (th.cfp.VM_FRAME_TYPE() != RbVm.VM_FRAME_MAGIC_FINISH) {
      rc.error_c.rb_bug("cfp consistency error");
    }

    //th.cfp++ // pop cf
    th.cfp = th.cfp_stack.pop() // pop cf

    return ret;
  }

  // New method, internals of vm_eval I guess
  public function
  vm_eval_array(th:RbThread, initial:Value, frame:RubyFrame):void
  {
    var ret:Value
    var instruction:String;
    var ops:Array;

    var prev_cfp:RbControlFrame = th.cfp;
    var prev_stack_index:int = th.cfp.sp.index;

    inner_loop_depth++;
    if (inner_loop_depth > 1) {
      rc.error_c.rb_bug("vm_eval_array inner_loop_depth "+inner_loop_depth);
    }

    while (th.cfp.pc_ary && th.cfp.pc_index < th.cfp.pc_ary.length) {

      if (th.cfp != prev_cfp) {
        //trace("vm_eval_array new cfp: " + th.cfp_stack.length + " sp: " + th.cfp.sp.index + " lfp: " + th.cfp.lfp.index);
      }

      prev_cfp = th.cfp;
      prev_stack_index = th.cfp.sp.index;

      var insn:* = th.cfp.pc_ary[th.cfp.pc_index];
      th.cfp.pc_index++;
      if (insn == undefined || insn == null) {
        rc.error_c.rb_bug("instruction undefined");
      }
      if (insn is Array) {
        instruction = insn[0];
        if (instruction == "trace") {
          continue;
        }

        //trace("eval loop: cfp: " + th.cfp_stack.length+" sp:"+th.cfp.sp.index + " bp:"+th.cfp.bp.index + "; " + insn);

        ops = insn.slice(1);
        frame[instruction].apply(this, ops);
        if (instruction == "leave") {
          //trace("leave");
          //break;
        }
        if (rc.TOPN(th.cfp.sp, 0) == rc.Qpause) {
          inner_loop_depth--;
          return;
        }
      } else {
        // line number
        // label
        // ?
      }
    }


    inner_loop_depth--;

  }


}
}
