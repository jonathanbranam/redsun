package
{
import flash.display.Sprite;

import ruby.internals.RbISeq;
import ruby.internals.RbVm;
import ruby.internals.RubyCore;
import ruby.internals.RubyFrame;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    var rc:RubyCore = new RubyCore();
    // Must do ruby_init to prep for creating iseq.
    rc.ruby_init();
    rc.ruby_run_node(rc.iseqval_from_func(ruby_func()));
  }

  protected function ruby_func():Function
  {
    return function (f:RubyFrame):void {
      f.putnil();
      f.putstring("THIS IS A STRING FROM RUBY!!");
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putstring("put this into local var");
      f.setlocal(2);

      f.putnil();
      f.getlocal(2);
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putnil();
      f.putstring("This is another string.");
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      f.putspecialobject(2);
      f.putnil();
      var class_iseq:RbISeq = new RbISeq();
      class_iseq.arg_size = 0;
      class_iseq.local_size = 1;
      class_iseq.stack_max = 1;
      class_iseq.type = RbVm.ISEQ_TYPE_CLASS;
      class_iseq.iseq_fn = function(f:RubyFrame):void {
        f.putnil();
        f.leave();
      }

      f.defineclass("A", class_iseq, 0);

      // [:leave]
      f.leave();
    };
  }

}
}
