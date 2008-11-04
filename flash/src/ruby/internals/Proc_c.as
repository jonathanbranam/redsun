package ruby.internals
{
public class Proc_c
{
  public var rc:RubyCore;

  import ruby.internals.RData;
  import ruby.internals.Value;

  public var rb_cUnboundMethod:RClass;
  public var rb_cMethod:RClass;
  public var rb_cBinding:RClass;
  public var rb_cProc:RClass;

  // proc.c:73
  public function
  rb_obj_is_proc(proc:Value):Boolean
  {
    if (rc.TYPE(proc) == Value.T_DATA &&
        RData(proc).dfree == proc_free) {
        return true;
    }
    else {
      return false;
    }
  }

  // proc.c:35
  public function
  proc_free(ptr:*):void
  {
    rc.error_c.rb_bug("proc_free");
  }

  // proc.c:63
  public function
  rb_proc_alloc(klass:RClass):Value
  {
    var obj:Value;
    var proc:RbProc;
    obj = rc.Data_Wrap_Struct(klass, new RbProc(), null, proc_free);
    return obj;
  }

  // proc.c:1740
  public function
  Init_Proc():void
  {
    // Proc
    rb_cProc = rc.class_c.rb_define_class("Proc", rc.object_c.rb_cObject);

    rc.eval_c.rb_eLocalJumpError = rc.class_c.rb_define_class("LocalJumpError", rc.error_c.rb_eStandardError);

    rc.eval_c.rb_eSysStackError = rc.class_c.rb_define_class("SystemStackError", rc.error_c.rb_eException);

    rb_cMethod = rc.class_c.rb_define_class("Method", rc.object_c.rb_cObject);

    rb_cUnboundMethod = rc.class_c.rb_define_class("UnboundMethod", rc.object_c.rb_cObject);

  }

  // proc.c:1857
  public function
  Init_Binding():void
  {
    rb_cBinding = rc.class_c.rb_define_class("Binding", rc.object_c.rb_cObject);
  }

}
}
