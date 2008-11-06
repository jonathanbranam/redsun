package ruby.internals
{
public class Numeric_c
{
  public var rc:RubyCore;

  import ruby.internals.RClass;
  import ruby.internals.Value;

  public var rb_cNumeric:RClass;
  public var rb_cFloat:RClass;
  public var rb_cInteger:RClass;
  public var rb_cFixnum:RClass;

  public var rb_eZeroDivError:RClass;
  public var rb_eFloatDomainError:RClass;

  public function
  INT2FIX(i:int):Value
  {
    return new RInt(i);
  }

  // numeric.c:94
  public function
  rb_num_zerodiv():void
  {
    rc.error_c.rb_raise(rb_eZeroDivError, "divided by 0");
  }

  // numeric.c:497
  public function
  rb_float_new(d:Number):RFloat
  {
    var flt:RFloat = new RFloat(rb_cFloat);
    flt.float_value = d;
    return flt;
  }

  // numeric.c:646
  public function
  flo_div(x:RFloat, y:Value):Value
  {
    var f_y:int;
    var d:Number;

    switch (rc.TYPE(y)) {
      case Value.T_FIXNUM:
        f_y = rc.FIX2LONG(y);
        return rc.DOUBLE2NUM(RFloat(x).float_value / Number(f_y));
      case Value.T_BIGNUM:
        rc.error_c.rb_bug("bignum not implemented");
        break;
      case Value.T_FLOAT:
        return rc.DOUBLE2NUM(RFloat(x).float_value / RFloat(y).float_value);
      default:
        rc.error_c.rb_bug("num coerce not implemented");
        break;
        //return rb_num_coerce_bin(x, y, "/");
    }
    return rc.Qnil;
  }

  // numeric.c:2064
  public function
  fix_to_s(argc:int, argv:StackPointer, x:Value):Value
  {
    var base:int;

    if (argc == 0) base = 10;
    else {
      var b:Value;

      b = argv.get_at(0);
      base = rc.FIX2LONG(b);
    }

    return rc.string_c.rb_str_new(RInt(x).value.toString(base));
  }

  // numeric.c:2209
  public function
  fixdivmod(x:int, y:int, divp:ByRef, modp:ByRef):void
  {
    var div:int, mod:int;

    if (y == 0) rb_num_zerodiv();
    if (y < 0) {
      if (x < 0) {
        div = -x / -y;
      } else {
        div = - (x / -y);
      }
    }
    else {
      if (x < 0) {
        div = - (-x / y);
      } else {
        div = x / y;
      }
    }
    mod = x - div*y;
    if ((mod < 0 && y > 0) || (mod > 0 && y < 0)) {
      mod += y;
      div -= 1;
    }
    if (divp) divp.v = div;
    if (modp) modp.v = mod;
  }

  // numeric.c:2264
  public function
  fix_divide(x:RInt, y:Value, op:String):Value
  {
    if (rc.FIXNUM_P(y)) {
      var div_ref:ByRef = new ByRef();

      fixdivmod(rc.FIX2LONG(x), rc.FIX2LONG(y), div_ref, null);
      return INT2FIX(div_ref.v);
    }
    switch (rc.TYPE(y)) {
      case Value.T_BIGNUM:
        rc.error_c.rb_bug("bignum not implemented");
        break;
      case Value.T_FLOAT:
        {
          var div:Number;

          if (op == "/") {
            div = Number(rc.FIX2LONG(x)) / RFloat(y).float_value;
            return rc.DOUBLE2NUM(div);
          }
          else {
            if (RFloat(y).float_value == 0) rb_num_zerodiv();
            div = Number(rc.FIX2LONG(x)) / RFloat(y).float_value;
            return INT2FIX(Math.floor(div));
          }
        }
      default:
        rc.error_c.rb_bug("divide coercion not implemented");
        break;
        //return rb_num_coerce_bin(x, y, op);
    }
    return rc.Qnil;
  }

  // numeric.c:2305
  public function
  fix_div(x:RInt, y:Value):Value
  {
    return fix_divide(x, y, '/');
  }

  public function
  Init_Numeric():void
  {
    rb_cNumeric = rc.class_c.rb_define_class("Numeric", rc.object_c.rb_cObject);
    rb_cInteger = rc.class_c.rb_define_class("Integer", rb_cNumeric);
    rb_cFixnum = rc.class_c.rb_define_class("Fixnum", rb_cInteger);
    rb_cFloat = rc.class_c.rb_define_class("Float", rb_cNumeric);

    rb_eZeroDivError = rc.class_c.rb_define_class("ZeroDivisionError", rc.error_c.rb_eStandardError);
    rb_eFloatDomainError = rc.class_c.rb_define_class("FloatDomainError", rc.error_c.rb_eRangeError);

    rc.class_c.rb_define_method(rb_cFixnum, "to_s", fix_to_s, -1);
    rc.class_c.rb_define_method(rb_cFixnum, "/", fix_div, 1);
    rc.class_c.rb_define_method(rb_cFloat, "/", flo_div, 1);
  }

}
}
