package
{
import flash.display.Screen;
import flash.events.Event;

import mx.core.UIComponent;
import mx.core.Window;
import mx.events.AIREvent;
import mx.events.FlexEvent;

import ruby.internals.RClass;
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
    rc.variable_c.rb_define_const(rc.rb_mFlashDisplay, "Screen", rc.wrap_flash_class(Screen));

    var rb_mMx:RClass = rc.class_c.rb_define_module("Mx");
    var rb_mMxCore:RClass = rc.class_c.rb_define_module_under(rb_mMx, "Core");
    rc.variable_c.rb_const_set(rb_mMxCore, rc.parse_y.rb_intern("UIComponent"), rc.wrap_flash_class(UIComponent));

    //variable_c.rb_const_set(rb_mFlashDisplay, parse_y.rb_intern("Sprite"), wrap_flash_class(Sprite));
    rc.run(bytecode, fullUIC);
  }

}
}
