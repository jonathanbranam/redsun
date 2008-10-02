package
{
import flash.display.Sprite;

public class MethodDecompile extends Sprite
{
  public function MethodDecompile()
  {
    super();
  }

  public function ifFunc():void
  {
    var b:Boolean = true;
    if (b) {
      trace("true");
    } else {
      trace("false");
    }
  }
  public function forFunc():void
  {
    for (var i:int = 0; i < 1; i++) {
      trace("i");
    }
  }

  public function someMath():void
  {
    var a:int,b:int,c:int;
    a = 1;
    b = 2;
    c = a*b;
    b = c/a;
    a = b+c;
    c = a*c+a*b;
  }

  private function privateFunc():void
  {
  }
  protected function protectedFunc():void
  {
  }
  public static function staticFunc():void
  {
  }

}
}
