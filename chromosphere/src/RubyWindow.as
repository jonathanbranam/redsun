package
{
import mx.core.UIComponent;
import mx.core.Window;
import mx.events.AIREvent;

import ruby.internals.RubyCore;

public class RubyWindow extends Window
{

  public var fullUIC:UIComponent;
  public var bytecode:String;
  public var rc:RubyCore;

  public function RubyWindow(bytecode:String=null)
  {
    this.bytecode = bytecode;
    super();
    this.width = 300;
    this.height = 300;
    this.addEventListener(AIREvent.WINDOW_COMPLETE, windowComplete);
  }

  protected function windowComplete(e:AIREvent):void
  {
    fullUIC = new UIComponent();
    fullUIC.enabled = true;
    fullUIC.focusEnabled = true;
    fullUIC.x = fullUIC.y = 0;
    fullUIC.percentWidth = fullUIC.percentHeight = 100;
    this.addChild(fullUIC);

    fullUIC.setFocus();
    rc = new RubyCore();
    rc.init();
    rc.variable_c.rb_define_global_const("TopSprite", rc.wrap_flash_obj(fullUIC));
    rc.variable_c.rb_define_global_const("AIRWindow", rc.wrap_flash_obj(this));
    rc.variable_c.rb_define_global_const("Document", rc.wrap_flash_obj(this));
    rc.define_flash_package("Mx");
    var result:int = rc.run(bytecode, fullUIC);
    trace("Execution of main ruby bytecode resulting in code: "+result);
  }

}
}
