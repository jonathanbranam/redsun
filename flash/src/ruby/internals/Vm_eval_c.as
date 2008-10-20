package ruby.internals
{
public class Vm_eval_c
{
  protected var rc:RubyCore;

  public var object_c:Object_c;

  public function Vm_eval_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function
  Init_vm_eval():void
  {
    //rb_define_global_function("catch", rb_f_catch, -1);
    //rb_define_global_function("throw", rb_f_throw, -1);

    //rb_define_global_function("loop", rb_f_loop, 0);

    //rb_define_method(rb_cBasicObject, "instance_eval", rb_obj_instance_eval, -1);
    //rb_define_method(rb_cBasicObject, "instance_exec", rb_obj_instance_exec, -1);
    //rb_define_private_method(rb_cBasicObject, "method_missing", rb_method_missing, -1);

    rb_define_method(object_c.rb_cBasicObject, "__send__", rb_f_send, -1);
    rb_define_method(object_c.rb_mKernel, "send", rb_f_send, -1);
    rb_define_method(object_c.rb_mKernel, "public_send", rb_f_public_send, -1);

    //rb_define_method(rb_cModule, "module_exec", rb_mod_module_exec, -1);
    //rb_define_method(rb_cModule, "class_exec", rb_mod_module_exec, -1);

    //rb_define_global_function("caller", rb_f_caller, -1);

  }

}
}
