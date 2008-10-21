package
{
import flash.display.Sprite;

import ruby.internals.RbISeq;
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
      f.putstring("hi");
      f.setlocal(2);

      f.getlocal(2);
      if (f.branchif()) {
        f.putnil();
        f.putstring("FAIL");
        f.send("puts", 1, f.Qnil, 8, f.Qnil);
        f.pop();
      }
      f.getlocal(2);
      if (f.branchunless()) {
        f.putnil();
        f.putstring("SUCCESS");
        f.send("puts", 1, f.Qnil, 8, f.Qnil);
        f.leave();
        return;
        f.pop();
      }

      f.putnil();
      f.leave();
      return;
    }
  }

  protected function ruby_func2():Function
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
      var class_iseq:RbISeq = f.rc.class_iseq_from_func("A", 0, 1, 1,
      function(f:RubyFrame):void {

        f.putspecialobject(1);
        f.putspecialobject(2);
        f.putobject("m");

        var m_iseq:RbISeq = f.rc.method_iseq_from_func("m", 0, 1, 1,
        function(f:RubyFrame):void {
          f.putstring("RETURNED from A#m");
          f.leave();
        });

        f.putiseq(m_iseq);
        f.send("core#define_method", 3, f.Qnil, 0, f.Qnil);

        f.putnil();
        f.leave();
      });

      f.defineclass("A", class_iseq, 0);
      f.pop();

      f.getinlinecache(f.Qnil, "label_31");
      f.getconstant("A");
      f.setinlinecache("label_24");
      f.send("new", 0, f.Qnil, 0, f.Qnil);
      f.setlocal(2);

      f.putnil();
      f.getlocal(2);
      f.send("m", 0, f.Qnil, 0, f.Qnil);
      f.send("puts", 1, f.Qnil, 8, f.Qnil);

      // [:leave]
      f.leave();
    };
  }

}
}
