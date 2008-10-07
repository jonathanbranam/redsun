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
    //RubyCore.init();
    //RGlobal.global.send_external(null, "const_set", "Document", this);
    basic_rb();
  }

  protected function basic_rb():void
  {
    RubyCore.run(this, function():* {
      this.define_class("Basic",
        this.send_external(this, "const_get", "Object"),
        function ():* {
          this.definemethod("initialize",
            function():* {
              //this.invoke_super();

              var local2:* = this.send_external(this, "const_get", "Flash").
                send_external(this, "const_get", "Display").
                send_external(this, "const_get", "Sprite").
                send_external(this, "new");
              local2.send_external(this, "graphics").send_external(this, "beginFill", 21760, 1);
              local2.send_external(this, "graphics").send_external(this, "drawCircle", 50, 50, 45);
              local2.send_external(this, "graphics").send_external(this, "endFill", 50, 50, 45);
              return this.const_get("Document").send_external(this, "addChild", local2);
            });
          return null;
        });

      var basicObj:* = this.send_external(null, "const_get", "Basic").send_external(this, "new");

    });
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
  }

}
}
