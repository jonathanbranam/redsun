package
{
import flash.display.Sprite;

public dynamic class RFMain extends Sprite
{
  public function RFMain()
  {
    super();
    graphics.lineStyle(1,1,1)
    graphics.beginFill(0xFF0000, 1)
    graphics.moveTo(0,0)
    graphics.drawRect(0,0, 100,100)

    testColor = 0x00FF00
    frameCount = 0

    var f:FixNum;
  }

  prototype.drawRect = function(color:*):* {
    graphics.clear();
    graphics.lineStyle(1,1,1)
    graphics.beginFill(color, 1)
    graphics.moveTo(0,0)
    graphics.drawRect(0,0, 100,100)
  }

  prototype.enterFrame = function(e:*):* {
    this.frameCount = this.frameCount + 1
    this.drawRect(testColor);
  }

  prototype.method1 = function(p1:*, p2:*=null):* {
    this.field1 = p1;
    if (p2) {
      this.field2 = p2;
    }
    this.method2(p1, function (i:*):* {
      trace("hello " + i);
    });
  }

  prototype.method2 = function(p1:*, f:Function):* {
    p1.upto(p2, function (i:*):* {
      f(i);
    });
  }

}
}
