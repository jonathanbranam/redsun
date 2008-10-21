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
    rc.run(this, ruby_func());
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
      var class_iseq:RbISeq = f.rc.class_iseq_from_func(0, 1, 1,
      function(f:RubyFrame):void {
        f.putnil();
        f.putstring("I am inside a class definition");
        f.send("puts", 1, f.Qnil, 8, f.Qnil);

        f.putnil();
        f.leave();
      });

      f.defineclass("A", class_iseq, 0);

      // [:leave]
      f.leave();
    };
  }

}
}
