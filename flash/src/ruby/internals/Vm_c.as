package ruby.internals
{
  import flash.utils.Dictionary;

public class Vm_c
{
  protected var rc:RubyCore;

  public var iseq_c:Iseq_c;
  public var vm_insnhelper_c:Vm_insnhelper_c;
  public var object_c:Object_c;
  public var class_c:Class_c;

  public var rb_cRubyVM:RClass;
  public var rb_cThread:RClass;
  public var rb_mRubyVMFrozenCore:Value;

  public function Vm_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function Init_VM():void
  {
    var opts:Value;
    var klass:RClass;
    var fcore:RClass;

    // ::VM
    rb_cRubyVM = class_c.rb_define_class("RubyVM", object_c.rb_cObject);
    // rb_undef_alloc_func(rb_cRubyVM);

    // ::VM::FrozenCore
    fcore = class_c.rb_class_new(object_c.rb_cBasicObject);
    fcore.flags = Value.T_ICLASS;
    // define various methods
    // rc.rb_obj_freeze(fcore);
    rb_mRubyVMFrozenCore = fcore;

    rb_cThread = class_c.rb_define_class("Thread", object_c.rb_cObject);
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

  public function
  vm_get_cbase(iseq:RbISeq, lfp:Array, dfp:Array):Value
  {
    var cref:Node = vm_insnhelper_c.vm_get_cref(iseq, lfp, dfp);
    var klass:Value = rc.Qundef;

    while (cref != null && cref != rc.Qnil) {
      if ((klass = cref.nd_clss) != null) {
        break;
      }
      cref = cref.nd_next;
    }

    return klass;
  }

  // vm_.c:747
  public function
  vm_cref_push(th:RbThread, klass:RClass, noex:int):Node
  {
    var cfp:RbControlFrame = vm_get_ruby_level_caller_cfp(th, th.cfp);
    var cref:Node = NEW_BLOCK(klass);
    cref.nd_file = null;
    cref.nd_visi = noex;

    if (cfp) {
      cref.nd_next = vm_insnhelper_c.vm_get_cref(cfp.iseq, cfp.lfp, cfp.dfp);
    }

    return cref;
  }


}
}
