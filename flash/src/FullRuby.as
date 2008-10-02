package
{
import flash.display.Sprite;

import ruby.internals.RGlobal;
import ruby.internals.RubyCore;

public class FullRuby extends Sprite
{
  public function FullRuby()
  {
    super();
    RubyCore.init();
    RGlobal.global.const_set("Document", this);
    basic_rb();
  }

  protected function basic_rb():void
  {
    /*
    RubyCore.define_class("Basic",
      RGlobal.global.const_get("Flash").const_get("Display").const_get("Sprite"),
      function ():* {
        this.sendInternal("definemethod","initialize",
          function():* {
            this.invoke_super();

            var local2:* = RGlobal.global.const_get("Flash").
              const_get("Display").
              const_get("Sprite").
              sendExternal("new");
            local2.sendExternal("graphics").sendExternal("beginFill", 21760, 1);
            local2.sendExternal("graphics").sendExternal("drawCircle", 50, 50, 45);
            local2.sendExternal("graphics").sendExternal("endFill", 50, 50, 45);
            return this.sendInternal("addChild", local2);
          });
        return null;
      });
    */
    RubyCore.define_class("BasicObject",
      RGlobal.global.const_get("Object"),
      function ():* {
        this.sendInternal("definemethod","initialize",
          function():* {
            this.invoke_super();

            var local2:* = RGlobal.global.const_get("Flash").
              const_get("Display").
              const_get("Sprite").
              sendExternal("new");
            local2.sendExternal("graphics").sendExternal("beginFill", 21760, 1);
            local2.sendExternal("graphics").sendExternal("drawCircle", 50, 50, 45);
            local2.sendExternal("graphics").sendExternal("endFill", 50, 50, 45);
            return RGlobal.global.const_get("Document").sendExternal("addChild", local2);
          });
        return null;
      });
  }

}
}
