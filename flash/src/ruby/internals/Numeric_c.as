package ruby.internals
{
public class Numeric_c
{
  public var rc:RubyCore;

  import ruby.internals.RClass;
  import ruby.internals.Value;

  public var rb_cNumeric:RClass;
  public var rb_cInteger:RClass;
  public var rb_cFixnum:RClass;

  public function
  INT2FIX(i:int):Value
  {
    return new RInt(i);
  }

  public function
  Init_Numeric():void
  {
    rb_cNumeric = rc.class_c.rb_define_class("Numeric", rc.object_c.rb_cObject);
    rb_cInteger = rc.class_c.rb_define_class("Integer", rb_cNumeric);
    rb_cFixnum = rc.class_c.rb_define_class("Fixnum", rb_cInteger);
  }

}
}
