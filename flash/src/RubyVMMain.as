package
{
import flash.display.Sprite;

import ruby.internals.RbControlFrame;
import ruby.internals.RbISeq;
import ruby.internals.RbThread;
import ruby.internals.RbVm;
import ruby.internals.RubyCore;
import ruby.internals.Value;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    var c:RubyCore = new RubyCore();
    // Must do ruby_init to prep for creating iseq.
    c.ruby_init();
    c.ruby_run_node(basic_rb(c));
  }

  protected function basic_rb(rc:RubyCore):Value
  {
    var iseq:RbISeq = new RbISeq();
    iseq.type = RbVm.ISEQ_TYPE_TOP;
    iseq.iseq_fn = function (rc:RubyCore, th:RbThread, cfp:RbControlFrame):void {
      // [:putnil]
      cfp.sp.push(rc.Qnil);

      // [:putstring, "hi"]
      cfp.sp.push(rc.rb_str_new("THIS IS A STRING FROM RUBY!!"));

      // [:send, :puts, 1, nil, 8, nil]
      rc.bc_send(th, cfp, rc.parse_y.rb_intern("puts"), 1, rc.Qnil, 8, rc.Qnil);

      // [:putstring, "hi"]
      cfp.sp.push(rc.rb_str_new("This is another string."));

      // [:send, :puts, 1, nil, 8, nil]
      rc.bc_send(th, cfp, rc.parse_y.rb_intern("puts"), 1, rc.Qnil, 8, rc.Qnil);

      // [:leave]
      rc.bc_leave(th, cfp);
    }
    return rc.Data_Wrap_Struct(rc.iseq_c.rb_cISeq, iseq, null, null);
  }

}
}
