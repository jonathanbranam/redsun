package
{
import flash.display.Sprite;

import ruby.internals.RubyCore;

public class RubyVMMain extends Sprite
{
  public function RubyVMMain()
  {
    super();
    RubyCore.init();
    basic_rb();
  }

  protected function basic_rb():void
  {
  }

}
}
