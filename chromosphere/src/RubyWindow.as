package
{
import flash.events.Event;

import mx.core.UIComponent;
import mx.core.Window;
import mx.events.AIREvent;
import mx.events.FlexEvent;

import ruby.internals.RubyCore;

public class RubyWindow extends Window
{

  public var fullUIC:UIComponent;
  public var bytecode:String;
  public var rc:RubyCore;

  public function RubyWindow()
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
    rc.variable_c.rb_define_global_const("AIRWindow", rc.wrap_flash_obj(this));
    rc.run(bytecode, fullUIC);
  }

}
}
