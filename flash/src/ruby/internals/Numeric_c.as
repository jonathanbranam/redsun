
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
    rb_cNumeric = rb_define_class("Numeric", rb_cObject);
    rb_cInteger = rb_define_class("Integer", rb_cNumeric);
    rb_cFixnum = rb_define_class("Fixnum", rb_cInteger);
  }
