package ruby.internals
{
public class RMethod
{
  public static const PRIVATE:uint = 1;
  public static const PROTECTED:uint = 2;

  public var klass:RClass;
  public var body:Function;
  public var flags:uint = 0;

  public function RMethod()
  {
  }

}
}
