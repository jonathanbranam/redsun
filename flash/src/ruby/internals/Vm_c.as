package ruby.internals
{
  import flash.utils.Dictionary;

public class Vm_c
{
  protected var rc:RubyCore;
  public var iseq_c:Iseq_c;

  public var rb_cRubyVM:RClass;
  public var rb_cThread:RClass;

  public function Vm_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function Init_VM():void
  {
    rb_cRubyVM = rc.rb_define_class("RubyVM", rc.rb_cObject);
    // rb_undef_alloc_func(rb_cRubyVM);

    rb_cThread = rc.rb_define_class("Thread", rc.rb_cObject);
    // rb_undef_alloc_func(rb_cThread);

    // VM bootstrap: phase 2
    {
      var vm:RbVm = rc.ruby_current_vm;
      var th:RbThread = rc.GET_THREAD();
      var filename:RString = rc.rb_str_new2("<dummy toplevel>");
      var iseqval:Value = iseq_c.rb_iseq_new(null, filename, filename, null, RbVm.ISEQ_TYPE_TOP);
      var th_self:Value;
      var iseq:RbISeq;

      // create vm object
      vm.self = rc.Data_Wrap_Struct(rb_cRubyVM, vm, null/*rb_vm_mark*/, null/*vm_free*/);

      // create main thread;
      th_self = th.self = rc.Data_Wrap_Struct(rb_cThread, th, null/*rb_thread_mark*/, null/*thread_free*/);
      vm.main_thread = th;
      vm.running_thread = th;
      th.vm = vm;
      th.top_wrapper = null;
      th.top_self = rc.rb_vm_top_self();
      rc.rb_thread_set_current(th);

      vm.living_threads = new Dictionary();
      vm.living_threads[th_self] = th.thread_id;

      //rc.rb_register_mark_object(iseqval);
      iseq = iseq_c.GetISeqPtr(iseqval);
      th.cfp.iseq = iseq;
      th.cfp.pc = iseq.iseq_fn;

    }
    vm_init_redefined_flag();
  }

  // vm.c:917
  protected function vm_init_redefined_flag():void {
    // create a bunch of operator related things

    //vm_opt_method_table = new Object();

  }

}
}
