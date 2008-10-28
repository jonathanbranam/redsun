package ruby.internals
{
public class Vm_c
{
  public var rc:RubyCore;


  import flash.utils.Dictionary;

  import ruby.internals.Node;
  import ruby.internals.RClass;
  import ruby.internals.RObject;
  import ruby.internals.RTag;
  import ruby.internals.RbControlFrame;
  import ruby.internals.RbISeq;
  import ruby.internals.RbProc;
  import ruby.internals.RbThread;
  import ruby.internals.RbVm;
  import ruby.internals.StackPointer;
  import ruby.internals.Value;

  public var rb_cRubyVM:RClass;
  public var rb_cThread:RClass;
  public var rb_mRubyVMFrozenCore:Value;

  protected var ruby_vm_global_state_version:int = 1;
  public var ruby_vm_redefined_flag:uint = 0;


  public function Init_VM():void
  {
    var opts:Value;
    var klass:RClass;
    var fcore:RClass;

    // ::VM
    rb_cRubyVM = rc.class_c.rb_define_class("RubyVM", rc.object_c.rb_cObject);
    // rb_undef_alloc_func(rb_cRubyVM);

    // ::VM::FrozenCore
    fcore = rc.object_c.rb_class_new(rc.object_c.rb_cBasicObject);
    fcore.flags = Value.T_ICLASS;
    fcore.name = "FrozenCore"
    klass = rc.class_c.rb_singleton_class(fcore);
    klass.name = "FrozenCoreSingleton";
    // define various methods
    rc.class_c.rb_define_method_id(klass, rc.id_c.id_core_define_method, m_core_define_method, 3);
    // rb_obj_freeze(fcore);
    rb_mRubyVMFrozenCore = fcore;

    rb_cThread = rc.class_c.rb_define_class("Thread", rc.object_c.rb_cObject);
    // rb_undef_alloc_func(rb_cThread);

    // VM bootstrap: phase 2
    {
      var vm:RbVm = rc.ruby_current_vm;
      var th:RbThread = rc.GET_THREAD();
      var filename:RString =rc.string_c.rb_str_new2("<dummy toplevel>");
      var iseqval:Value = rc.iseq_c.rb_iseq_new(null, filename, filename, null, RbVm.ISEQ_TYPE_TOP);
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
      th.top_self = rb_vm_top_self();
      rb_thread_set_current(th);

      vm.living_threads = new Dictionary();
      vm.living_threads[th_self] = th.thread_id;

      //rb_register_mark_object(iseqval);
      iseq = rc.iseq_c.GetISeqPtr(iseqval);
      th.cfp.iseq = iseq;
      th.cfp.pc_fn = iseq.iseq_fn;
      th.cfp.pc_ary = iseq.iseq;
      th.cfp.pc_index = 0;

    }
    vm_init_redefined_flag();
  }

  // vm.c:917
  protected function
  vm_init_redefined_flag():void
  {
    // create a bunch of operator related things

    //vm_opt_method_table = new Object();

  }

  public function
  vm_get_cbase(iseq:RbISeq, lfp:StackPointer, dfp:StackPointer):Value
  {
    var cref:Node = rc.vm_insnhelper_c.vm_get_cref(iseq, lfp, dfp);
    var klass:Value = rc.Qundef;

    while (cref != null && cref != rc.Qnil) {
      if ((klass = cref.nd_clss) != null) {
        break;
      }
      cref = cref.nd_next;
    }

    return klass;
  }

  public function
  RUBY_VM_PREVIOUS_CONTROL_FRAME(th:RbThread, cfp:RbControlFrame):RbControlFrame
  {
    var index:int = th.cfp_stack.indexOf(cfp);
    if (index > 0) {
      return th.cfp_stack[index-1];
    } else {
      return null;
    }
  }

  // vm_core.h:628
  public function
  RUBY_VM_IFUNC_P(ptr:Value):Boolean
  {
    return ptr.BUILTIN_TYPE() == Value.T_NODE;
  }

  // vm_core.h:629
  public function
  RUBY_VM_NORMAL_ISEQ_P(iseq:Value):Boolean
  {
    return iseq && !RUBY_VM_IFUNC_P(iseq);
  }

  public function
  RUBY_VM_CONTROL_FRAME_STACK_OVERFLOW_P(th:RbThread, cfp:RbControlFrame):Boolean
  {
    return cfp == null;
  }

  // vm.c:112
  public function
  vm_get_ruby_level_caller_cfp(th:RbThread, cfp:RbControlFrame):RbControlFrame
  {
    if (RUBY_VM_NORMAL_ISEQ_P(cfp.iseq)) {
      return cfp;
    }

    cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);

    while (!RUBY_VM_CONTROL_FRAME_STACK_OVERFLOW_P(th, cfp)) {
      if (RUBY_VM_NORMAL_ISEQ_P(cfp.iseq)) {
        return cfp;
      }

      if ((cfp.flag & RbVm.VM_FRAME_FLAG_PASSED) == 0) {
        break;
      }

      cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);
    }

    return null;
  }

  // vm_.c:747
  public function
  vm_cref_push(th:RbThread, klass:RClass, noex:int):Node
  {
    var cfp:RbControlFrame = vm_get_ruby_level_caller_cfp(th, th.cfp);
    var cref:Node = rc.NEW_BLOCK(klass);
    cref.nd_file = null;
    cref.nd_visi = noex;

    if (cfp) {
      cref.nd_next = rc.vm_insnhelper_c.vm_get_cref(cfp.iseq, cfp.lfp, cfp.dfp);
    }

    return cref;
  }

  public function
  main_to_s(obj:Value):Value
  {
    return rc.string_c.rb_str_new2("main");
  }

  public function
  Init_top_self():void
  {
    var vm:RbVm = rc.GET_VM();

    vm.top_self = rc.object_c.rb_obj_alloc(rc.object_c.rb_cObject);
    rc.class_c.rb_define_singleton_method(rb_vm_top_self(), "to_s", main_to_s, 0);
  }

  // vm.c:1943
  public function
  rb_vm_top_self():Value
  {
    return rc.GET_VM().top_self;
  }

  // vm_core.h:686
  public function
  rb_thread_set_current_raw(th:RbThread):void
  {
    rc.ruby_current_thread = th;
  }

  // vm_core.h:687
  public function
  rb_thread_set_current(th:RbThread):void
  {
    rb_thread_set_current_raw(th);
    th.vm.running_thread = th;
  }

  // vm.c:1415
  public function
  vm_init2(vm:RbVm):void
  {
    vm.src_encoding_index = -1;
  }

  // vm.c:1431
  public function
  thread_recycle_stack(size:int):StackPointer
  {
    return new StackPointer(new Array(size));
  }


  // vm.c:1587
  public function
  th_init2(th:RbThread, self:Value):void
  {
    th.self = self;

    th.stack_size = RbVm.RUBY_VM_THREAD_STACK_SIZE;
    th.stack = thread_recycle_stack(th.stack_size);

    th.cfp_stack = new Array();
    //th.cfp = new RbControlFrame();

    rc.vm_insnhelper_c.vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_TOP, rc.Qnil, null,
                  null, null, 0, th.stack, null, 1);

    th.status = RbThread.THREAD_RUNNABLE;
    th.errinfo = rc.Qnil;
    th.last_status = rc.Qnil;
  }


  // vm.c:1610
  public function
  th_init(th:RbThread, self:Value):void
  {
    th_init2(th, self);
  }

  // vm_core.h:368
  public function
  GetThreadPtr(obj:*):RbThread
  {
    return RbThread(obj);
  }

  // vm.c:1616
  public function
  ruby_thread_init(self:Value):Value
  {
    var th:RbThread;
    var vm:RbVm = rc.GET_THREAD().vm;
    th = GetThreadPtr(self);

    th_init(th, self);
    th.vm = vm;

    th.top_wrapper = null;
    th.top_self = rb_vm_top_self();

    return self;
  }

  // vm_core.h:174
  public function
  GetCoreDataFromValue(obj:Value):*
  {
    return RData(obj).data;
  }


  // vm.c:1573
  public function
  thread_alloc(klass:RClass):Value
  {
    var obj:Value;
    obj = rc.Data_Wrap_Struct(klass, new RbThread(), null/*rb_thread_mark*/, null/*thread_free*/);

    return obj;
  }

  // vm.c:1631
  public function
  rb_thread_alloc(klass:RClass):Value
  {
    var self:Value = thread_alloc(klass);
    ruby_thread_init(self);
    return self;
  }

  // vm.c:1910
  public function
  Init_BareVM():void
  {
    var th:RbThread = new RbThread();
    var vm:RbVm = new RbVm();
    rb_thread_set_current_raw(th);

    vm_init2(vm);

    rc.ruby_current_vm = vm;

    th_init2(th, null);

    th.vm = vm;
    rc.thread_c.ruby_thread_init_stack(th);
  }

  public var finish_insn_seq:Function =
    function (th:RbThread, cfp:RbControlFrame):Value {
      this.finish();
      return this.Qnil;
    };

  // vm.c:54
  public function
  rb_vm_set_finish_env(th:RbThread):Value
  {
    rc.vm_insnhelper_c.vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_FINISH, rc.Qnil,
                  th.cfp.lfp.get_at(0), null, null, 0,
                  th.cfp.sp.clone(), null, 1);
    th.cfp.pc_fn = finish_insn_seq;
    return rc.Qtrue;
  }


  // vm.c:64
  public function
  vm_set_top_stack(th:RbThread, iseqval:Value):void
  {
    var iseq:RbISeq;

    iseq = rc.iseq_c.GetISeqPtr(iseqval);

    if (iseq.type != RbVm.ISEQ_TYPE_TOP) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "Not a toplevel InstructionSequence");
    }

    rb_vm_set_finish_env(th);

    rc.vm_insnhelper_c.vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_TOP, th.top_self, null, iseq.iseq_fn,
                  iseq.iseq, 0, th.cfp.sp.clone(), null, iseq.local_size);
  }

  // vm.c:1256
  public function
  rb_iseq_eval(iseqval:Value):Value
  {
    var th:RbThread = rc.GET_THREAD();
    vm_set_top_stack(th, iseqval);
    // TODO: @skip
    //rb_define_global_const("TOPLEVEL_BINDING", rb_binding_new());
    return vm_eval_body(th);
  }

  // vm.c:1051
  public function
  vm_eval_body(th:RbThread):Value
  {
    var result:Value;
    var initial:Value;

    try {
      result = rc.vm_evalbody_c.vm_eval(th, initial);
    } catch (e:Error) {
      trace("error: " +e.message);
      trace(e.getStackTrace());


      // Exception handling.

      // if state == TAG_RETRY
      // search catch_table for RETRY entry
      // etc.

      th.cfp = th.cfp_stack.pop();
      if (th.cfp.pc_fn != finish_insn_seq) {
        trace("goto exception_handler");
        // goto exception_handler;
      } else {
        rc.vm_insnhelper_c.vm_pop_frame(th);
        // th.errinfo = err;
        // TH_POP_TAG2();
        // JUMP_TAG(state);
      }
    }

    return result;
  }

  // vm.c:100
  public function
  vm_get_ruby_level_next_cfp(th:RbThread, cfp:RbControlFrame):RbControlFrame
  {
    while (!RUBY_VM_CONTROL_FRAME_STACK_OVERFLOW_P(th, cfp)) {
      if (RUBY_VM_NORMAL_ISEQ_P(cfp.iseq)) {
        return cfp;
      }
      cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);
    }
    return null;
  }

  // vm.c:727
  public function
  vm_cref():Node
  {
    var th:RbThread = rc.GET_THREAD();
    var cfp:RbControlFrame = vm_get_ruby_level_next_cfp(th, th.cfp);
    return rc.vm_insnhelper_c.vm_get_cref(cfp.iseq, cfp.lfp, cfp.dfp);
  }

  // vm.c:1686
  public function
  m_core_define_method(self:Value, cbase:Value, sym:Value, iseqval:Value):Value
  {
    // TODO: @skipped rewind cfp
    // REWIND_CFP({
    var th__:RbThread = rc.GET_THREAD();
    var cur_cfp:RbControlFrame = th__.cfp;
    var popped_cfp:RbControlFrame = th__.cfp_stack.pop();
    th__.cfp = popped_cfp;
      vm_define_method(rc.GET_THREAD(), cbase, rc.SYM2ID(sym), iseqval, false, vm_cref());
    th__.cfp_stack.push(popped_cfp);
    th__.cfp = cur_cfp;
    //});
    return rc.Qnil;
  }

  // vm.c:1643
  public function
  vm_define_method(th:RbThread, obj:Value, id:int, iseqval:Value,
                   is_singleton:Boolean, cref:Node):void
  {
    var newbody:Node;
    var klass:RClass = cref.nd_clss;
    var noex:int = cref.nd_visi;
    var miseq:RbISeq;
    miseq = rc.iseq_c.GetISeqPtr(iseqval);

    if (rc.NIL_P(klass)) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "no class/module to add method");
    }

    if (is_singleton) {
      // TODO: @skipped test for fixnum and symbol
      // TODO: @skipped test for frozen
      klass = rc.class_c.rb_singleton_class(obj);
      noex = Node.NOEX_PUBLIC;
    }

    // dup
    rc.COPY_CREF(miseq.cref_stack, cref);
    miseq.klass = klass;
    miseq.defined_method_id = id;
    newbody = rc.NEW_NODE(Node.RUBY_VM_METHOD_NODE, 0, miseq.self, 0);
    rc.vm_method_c.rb_add_method(klass, id, newbody, noex);

    if (!is_singleton && noex == Node.NOEX_MODFUNC) {
      rc.vm_method_c.rb_add_method(rc.class_c.rb_singleton_class(klass), id, newbody, Node.NOEX_PUBLIC);
    }
    INC_VM_STATE_VERSION();
  }

  // vm.h:237
  public function
  INC_VM_STATE_VERSION():void
  {
    ruby_vm_global_state_version = (ruby_vm_global_state_version+1) & 0x8fffffff;
  }

  // vm.h:236
  public function
  GET_VM_STATE_VERSION():int
  {
    return ruby_vm_global_state_version;
  }

  // vm.c:821
  public function
  vm_localjump_error(mesg:String, value:Value, reason:int):void
  {
    var exc:Value = make_localjump_error(mesg, value, reason);
    rc.eval_c.rb_exc_raise(exc);
  }

  // vm.c:789
  public function
  make_localjump_error(mesg:String, value:Value, reason:int):Value
  {
    var exc:RObject = rc.error_c.rb_exc_new2(rc.eval_c.rb_eLocalJumpError, mesg);
    var id:int;

    switch (reason) {
      case RTag.TAG_BREAK:
        id = rc.CONST_ID("break");
        break;
      case RTag.TAG_REDO:
        id = rc.CONST_ID("redo");
        break;
      case RTag.TAG_RETRY:
        id = rc.CONST_ID("retry");
        break;
      case RTag.TAG_NEXT:
        id = rc.CONST_ID("next");
        break;
      case RTag.TAG_RETURN:
        id = rc.CONST_ID("return");
        break;
      default:
        id = rc.CONST_ID("noreason");
        break;
    }
    rc.variable_c.rb_iv_set(exc, "@exit_value", value);
    rc.variable_c.rb_iv_set(exc, "@reason", rc.ID2SYM(id));
    return exc;

  }

  // vm_core.h:526
  public function
  GetProcPtr(obj:Value):RbProc
  {
    return GetCoreDataFromValue(obj);
  }

}
}
