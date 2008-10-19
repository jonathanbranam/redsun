package ruby.internals
{
public class String_c
{
  protected var rc:RubyCore;
  public var parse_y:Parse_y;
  public var error_c:Error_c;

  public function String_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function rb_str_intern(s:Value):Value {
    var str:Value = s;//RB_GC_GUARD(s);
    var sym:Value;
    var id:int, id2:int;

    id = parse_y.rb_intern_str(str);
    sym = rc.ID2SYM(id);
    id2 = rc.SYM2ID(sym);

    if (id != id2) {
      var name:String = parse_y.rb_id2name(id2);

      if (name) {
        rc.rb_raise(error_c.rb_eRuntimeError, "symbol table overflow ("+name+" given for "+
                    rc.RSTRING_PTR(str)+")");
      } else {
        rc.rb_raise(error_c.rb_eRuntimeError, "symbol table overflow (symbol "+rc.RSTRING_PTR(str)+")");
      }
    }
    return sym;
  }

}
}
