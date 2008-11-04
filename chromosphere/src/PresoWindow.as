package
{
import flash.events.Event;

import mx.core.UIComponent;
import mx.core.Window;
import mx.events.AIREvent;
import mx.events.FlexEvent;

import ruby.internals.RubyCore;
import ruby.internals.Value;

public class PresoWindow extends Window
{

  public var fullUIC:UIComponent;
  public var bytecode:String;
  public var rc:RubyCore;

  public function PresoWindow()
  {
    super();
    this.width = 300;
    this.height = 300;
    this.addEventListener(AIREvent.WINDOW_COMPLETE, windowComplete);
  }

  protected function windowComplete(e:AIREvent):void
  {
    fullUIC = new UIComponent();
    fullUIC.x = fullUIC.y = 0;
    fullUIC.percentWidth = fullUIC.percentHeight = 100;
    fullUIC.addEventListener(FlexEvent.CREATION_COMPLETE, uicCC);
    this.addChild(fullUIC);
  }

  protected function uicCC(e:Event):void
  {
    rc = new RubyCore();
    rc.init();
    rc.variable_c.rb_define_global_const("TopSprite", rc.wrap_flash_obj(fullUIC));
    var this_val:Value = rc.wrap_flash_obj(this);
    rc.variable_c.rb_define_global_const("AIRWindow", this_val);
    rc.variable_c.rb_define_global_const("Document", this_val);
    rc.run(bytecode, fullUIC);
  }

}
}
