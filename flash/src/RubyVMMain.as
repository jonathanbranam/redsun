package
{
import flash.display.Sprite;

import ruby.internals.Node;
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
    c.main(basic_rb(c));
  }

  protected function basic_rb(c:RubyCore):Node
  {
    var iseq:RbISeq = new RbISeq();
    iseq.type = RbVm.ISEQ_TYPE_TOP;
    iseq.iseq_fn = function (th:RbThread, cfp:RbControlFrame):Value {
      return this.Qnil;
    }
    return Node(iseq);
  }

}
}
