package
{
import flash.display.Sprite;

import ruby.internals.RubyCore;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    var c:RubyCore = new RubyCore();
    c.init();
    basic_rb(c);
  }

  protected function basic_rb(c:RubyCore):void
  {
  }

}
}
