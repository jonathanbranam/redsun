package ruby.internals
{
import ruby.RObject;

public dynamic class RGlobal extends RObject
{
  public static var global:RGlobal;

  public function RGlobal(klass:RClass=null)
  {
    super(klass);
  }

}
}
