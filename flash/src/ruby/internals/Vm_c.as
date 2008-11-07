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
  public var rb_cEnv:RClass;
  public var rb_mRubyVMFrozenCore:Value;

  protected var ruby_vm_global_state_version:int = 1;
  public var ruby_vm_redefined_flag:uint = 0;
  public var vm_opt_method_table:Object;

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
    rc.class_c.rb_define_method_id(klass, rc.id_c.id_core_define_method,
                                   m_core_define_method, 3);
    rc.class_c.rb_define_method_id(klass, rc.id_c.id_core_define_singleton_method,
                                   m_core_define_singleton_method, 3);
    // rb_obj_freeze(fcore);
    rb_mRubyVMFrozenCore = fcore;

    // ::VM::Env
    rb_cEnv = rc.class_c.rb_define_class_under(rb_cRubyVM, "Env", rc.object_c.rb_cObject);

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

  // vm.c:46
  public function
  rb_vm_change_state():void
  {
    INC_VM_STATE_VERSION();
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
    if (th.cfp == cfp) {
      return th.cfp_stack[th.cfp_stack.length-1];
    }
    var index:int = th.cfp_stack.indexOf(cfp);
    if (index > 0) {
      return th.cfp_stack[index-1];
    } else {
      rc.error_c.rb_bug("couldn't find control frame");
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

  // vm.c:894
  public function
  rb_vm_check_redefinition_opt_method(node:Node):void
  {
    var bop:int;

    if (vm_opt_method_table[node] != undefined) {
      bop = vm_opt_method_table[node];
      ruby_vm_redefined_flag |= bop;
    }
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

  // vm.h:218
  public function
  ENV_IN_HEAP_P(th:RbThread, env:StackPointer):Boolean
  {
    if (th.stack.stack != env.stack) {
      return true;
    }
    else {
      return !(th.stack.index < env.index && env.index < (th.stack.index + th.stack_size));
    }
  }

  // vm.h:220
  public function
  ENV_VAL(env:StackPointer):Value
  {
    return env.get_at(1);
  }

  // vm.c:178
  public function
  env_alloc():Value
  {
    var obj:Value;
    var env:RbEnv = new RbEnv();
    obj = rc.Data_Wrap_Struct(rb_cEnv, env, null, null);
    env.env = null;
    env.prev_envval = null;
    env.block.block_iseq = null;
    return obj;
  }

  // vm.c:226
  protected function
  vm_make_env_each(th:RbThread, cfp:RbControlFrame,
                   envptr:StackPointer, endptr:StackPointer):Value
  {
    var envval:Value, penvval:Value;
    var env:RbEnv;
    var nenvptr:StackPointer;
    var i:int, local_size:int;

    if (ENV_IN_HEAP_P(th, envptr)) {
      return ENV_VAL(envptr);
    }

    if (!envptr.equals(endptr)) {
      var penvptr:StackPointer = envptr.get_at(0);
      penvptr = penvptr.clone();
      var pcfp:RbControlFrame = cfp;

      if (ENV_IN_HEAP_P(th, penvptr)) {
        penvval = ENV_VAL(penvptr);
      }
      else {
        while (!pcfp.dfp.equals(penvptr)) {
          pcfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th, pcfp);
          if (pcfp.dfp == null) {
            rc.error_c.rb_bug("invalid dfp");
          }
        }
        penvval = vm_make_env_each(th, pcfp, penvptr.clone(), endptr.clone());
        cfp.lfp = pcfp.lfp.clone();
        envptr.set_top(pcfp.dfp.clone());
      }
    }

    // allocate env
    envval = env_alloc();
    env = GetEnvPtr(envval);

    if (!RUBY_VM_NORMAL_ISEQ_P(cfp.iseq)) {
      local_size = 2;
    }
    else {
      local_size = cfp.iseq.local_size;
    }

    env.env_size = local_size + 1 + 2;
    env.local_size = local_size;
    env.env = new StackPointer(new Array(env.env_size));
    env.prev_envval = penvval;

    for (i = 0; i <= local_size; i++) {
      var d:* = envptr.get_at(-local_size + i);
      if (d is StackPointer) {
        d = StackPointer(d).clone();
      }
      env.env.set_at(i, d);
      // Some removed code here
    }

    envptr.set_at(0, envval);                         // GC mark
    nenvptr = env.env.clone_down_stack(i - 1);
    nenvptr.set_at(1, envval);                // frame self
    nenvptr.set_at(2, penvval);               // frame prev env object

    // reset lfp/dfp in cfp
    cfp.dfp = nenvptr.clone();
    if (envptr.equals(endptr)) {
      cfp.lfp = nenvptr.clone();
    }

    // as Binding
    env.block.self = cfp.self;
    env.block.lfp = cfp.lfp.clone();
    env.block.dfp = cfp.dfp.clone();
    env.block.block_iseq = cfp.iseq;

    if (!RUBY_VM_NORMAL_ISEQ_P(cfp.iseq)) {
      // TODO
      env.block.block_iseq = null;
    }
    return envval;
  }

  // vm.c:344
  public function
  vm_make_env_object(th:RbThread, cfp:RbControlFrame):Value
  {
    var envval:Value;

    if (cfp.VM_FRAME_TYPE() == RbVm.VM_FRAME_MAGIC_FINISH) {
      // for method missing
      cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);
    }

    envval = vm_make_env_each(th, cfp, cfp.dfp.clone(), cfp.lfp.clone());

    // if (PROCDEBUG)

    return envval;
  }

  // vm.c:375
  public function
  vm_make_proc_from_block(th:RbThread, cft:RbControlFrame,
                          block:RbBlock, klass:RClass):Value
  {
    var procval:Value;
    var bcfp:RbControlFrame;
    var bdfp:StackPointer // to gc mark

    procval = block.proc;
    if (procval && RBasic(procval).klass == klass) {
      return procval;
    }

    bcfp = RUBY_VM_GET_CFP_FROM_BLOCK_PTR(block);
    bdfp = bcfp.dfp.clone();
    procval = vm_make_proc(th, bcfp, block, klass);
    if (!block.proc) block.proc = procval;
    return procval;
  }

  // vm.c:411
  public function
  vm_make_proc(th:RbThread, cfp:RbControlFrame,
               block:RbBlock, klass:RClass):Value
  {
    var procval:Value, envval:Value, blockprocval:Value;
    var proc:RbProc;

    if (cfp.lfp.get_at(0) != null && cfp.lfp.get_at(0) is RbBlock) {
      // ptr & 0x02
      if (true) { //!RUBY_VM_CLASS_SPECIAL_P(cfp.lfp.get_at(0))) {
        var p:RbProc;

        blockprocval = vm_make_proc_from_block(
          th, cfp, RbBlock(cfp.lfp.get_at(0)), klass);

        p = GetProcPtr(blockprocval);
        cfp.lfp.set_at(0, p.block);
      }
    }
    envval = vm_make_env_object(th, cfp);

    //if (PROCDEBUG) {
    //  check_env_value(envval);
    //}
    procval = rc.proc_c.rb_proc_alloc(klass);
    proc = GetProcPtr(procval);
    proc.blockprocval = blockprocval;
    proc.block.self = block.self;
    proc.block.lfp = block.lfp.clone();
    proc.block.dfp = block.dfp.clone();
    proc.block.block_iseq = block.block_iseq;
    proc.block.proc = procval;
    proc.envval = envval;
    proc.safe_level = th.safe_level;

    // if (VMDEBUG) {
    // }

    return procval;
  }

  // vm.c:443
  public function
  invoke_block_from_c(th:RbThread, block:RbBlock,
                      self:Value, argc:int, argv:StackPointer,
                      blockptr:RbBlock, cref:Node):Value
  {
    if (block.block_iseq.BUILTIN_TYPE() != Value.T_NODE) {
      var iseq:RbISeq = block.block_iseq;
      var cfp:RbControlFrame = th.cfp;
      var i:int, opt_pc:int;
      var arg_size:int = iseq.arg_size;
      var type:int = rc.vm_insnhelper_c.block_proc_is_lambda(block.proc) ?
                     RbVm.VM_FRAME_MAGIC_LAMBDA :
                     RbVm.VM_FRAME_MAGIC_BLOCK;

      rb_vm_set_finish_env(th);

      // CHECK_STACK_OVERFLOW(cfp, argc + iseq.stack_max);

      for (i = 0; i < argc; i++) {
        cfp.sp.set_at(i, argv.get_at(i));
      }

      opt_pc = rc.vm_insnhelper_c.vm_yield_setup_args(th, iseq, argc, cfp.sp.clone(), blockptr,
                                   type == RbVm.VM_FRAME_MAGIC_LAMBDA);

      rc.vm_insnhelper_c.vm_push_frame(th, iseq, type,
                                       self, block.dfp.clone(),
                                       iseq.iseq_fn, iseq.iseq, opt_pc,
                                       cfp.sp.clone_down_stack(arg_size),
                                       block.lfp.clone(), iseq.local_size-arg_size);

      if (cref) {
        th.cfp.dfp.set_at(-1, cref);
      }

      return vm_eval_body(th);
    }
    else {
      return rc.vm_insnhelper_c.vm_yield_with_cfunc(th, block, self, argc, argv, blockptr);
    }
  }

  // vm.c:482
  public function
  check_block(th:RbThread):RbBlock
  {
    var blockptr:RbBlock = th.cfp.lfp.get_at(0);

    if (blockptr == null) {
      vm_localjump_error("no block given", rc.Qnil, 0);
    }

    return blockptr;
  }

  // vm.c:501
  public function
  vm_yield(th:RbThread, argc:int, argv:StackPointer):Value
  {
    var blockptr:RbBlock = check_block(th);
    return invoke_block_from_c(th, blockptr, blockptr.self,
                               argc, argv, null, null);
  }

  // vm.c:508
  public function
  vm_invoke_proc(th:RbThread, proc:RbProc, self:Value,
                 argc:int, argv:StackPointer, blockptr:RbBlock):Value
  {
    var val:Value = rc.Qundef;
    var state:int;
    var stored_safe:int = th.safe_level;
    var cfp:RbControlFrame = th.cfp;

    // TH_PUSH_TAG(th)
    // if ((state = EXEC_TAG()) == 0) {
    if (!proc.is_from_method) {
      th.safe_level = proc.safe_level;
    }
    val = invoke_block_from_c(th, proc.block, self, argc, argv, blockptr, null);
    // TH_POP_TAG();

    if (!proc.is_from_method) {
      th.safe_level = stored_safe;
    }

    // TODO: handle exceptions and TAGS

    return val;
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

  // vm_core.h:589
  public function
  GetEnvPtr(obj:Value):RbEnv
  {
    return GetCoreDataFromValue(obj);
  }

  // vm.c:1695
  public function
  m_core_define_singleton_method(self:Value, cbase:Value, sym:Value, iseqval:Value):Value
  {
    // REWIND_CFP({
    var th__:RbThread = rc.GET_THREAD();
    var cur_cfp:RbControlFrame = th__.cfp;
    var popped_cfp:RbControlFrame = th__.cfp_stack.pop();
    th__.cfp = popped_cfp;
      vm_define_method(rc.GET_THREAD(), cbase, rc.SYM2ID(sym), iseqval, true, vm_cref());
    th__.cfp_stack.push(popped_cfp);
    th__.cfp = cur_cfp;
    //});
    return rc.Qnil;
  }

  // vm_core.h:635
  public function
  RUBY_VM_GET_CFP_FROM_BLOCK_PTR(b:RbBlock):RbControlFrame
  {
    return RbControlFrame(b);
  }

  // vm_core.h:634
  public function
  RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp:RbControlFrame):RbBlock
  {
    return cfp;
  }

  // vm.c:904
  public function
  add_opt_method(klass:RClass, mid:int, bop:int):void
  {
    var node:Node;
    if (klass.m_tbl[mid] != undefined) {
      node = klass.m_tbl[mid];
      if (Node(Node(node.nd_body).nd_body).nd_type() == Node.NODE_CFUNC) {
        vm_opt_method_table[node] = bop;
      }
    }
    else {
      rc.error_c.rb_bug("undefined optimized method: " + rc.parse_y.rb_id2name(mid));
    }
  }

  // vm.c:917
  public function
  vm_init_redefined_flag():void
  {
    var mid:int;
    var bop:int;

    vm_opt_method_table = new Dictionary();

    rc.error_c.rb_warn("redifined tracking not implemented");
    return;

    mid = Id_c.idPLUS;
    bop = RbVm.BOP_PLUS;
    add_opt_method(rc.numeric_c.rb_cFixnum, mid, bop);
  }


}
}
