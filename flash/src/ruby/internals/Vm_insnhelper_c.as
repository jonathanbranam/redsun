package ruby.internals
{
public class Vm_insnhelper_c
{
  public var rc:RubyCore;



  import ruby.internals.ByRef;
  import ruby.internals.Node;
  import ruby.internals.RClass;
  import ruby.internals.RbBlock;
  import ruby.internals.RbControlFrame;
  import ruby.internals.RbISeq;
  import ruby.internals.RbProc;
  import ruby.internals.RbThread;
  import ruby.internals.RbVm;
  import ruby.internals.StackPointer;
  import ruby.internals.Value;

  public function
  GET_PREV_DFP(dfp:StackPointer):StackPointer
  {
    // The boolean operation below simply removes the GC_GUARD.
    // ((VALUE *)((dfp)[0] & ~0x03))
    return dfp.get_at(0);
  }

  public function
  GET_ISEQ(cfp:RbControlFrame):RbISeq
  {
    return cfp.iseq;
  }

  // vm_insnhelper.c:946
  public function
  vm_get_cref(iseq:RbISeq, lfp:StackPointer, dfp:StackPointer):Node
  {
    var cref:Node = null;

    while (1) {
      if (lfp.equals(dfp)) {
        cref = iseq.cref_stack;
        break;
      } else if (dfp.get_at(-1) != rc.Qnil) {
        cref = dfp.get_at(-1);
        break;
      }
      dfp = StackPointer(GET_PREV_DFP(dfp));
    }

    if (cref == null) {
      rc.error_c.rb_bug("vm_get_cref: unreachable");
    }

    return cref;
  }


  // vm_insnhelper.c:24
  public function
  vm_push_frame(th:RbThread, iseq:RbISeq, type:uint, self:Value, specval:Object,
                pc_fn:Function, pc_ary:Array, pc_index:int, sp:StackPointer,
                lfp:StackPointer, local_size:int):RbControlFrame
  {
    // rb_control_frame_t * const cfp = th->cfp = th->cfp - 1;
    var cfp:RbControlFrame = new RbControlFrame();
    th.cfp_stack.push(th.cfp);
    th.cfp = cfp;
    var i:int;

    for (i = 0; i < local_size; i++) {
      sp.set_top(rc.Qnil);
      sp.inc_index();
      // *sp = Qnil;
      // sp++;
    }

    // This might be an RbBlock.
    // *sp = GC_GUARDED_PTR(specval);
    sp.set_top(specval);

    if (lfp == null) {
      lfp = sp.clone();
    }

    cfp.pc_fn = pc_fn;
    cfp.pc_ary = pc_ary;
    cfp.pc_index = pc_index;
    cfp.sp = sp.clone_down_stack(1); // sp + 1
    cfp.bp = sp.clone_down_stack(1); // sp + 1
    cfp.iseq = iseq;
    cfp.flag = type;
    cfp.self = self;
    cfp.lfp = lfp;
    cfp.dfp = sp.clone();
    cfp.proc = null;

    return cfp;
  }

  // vm_insnhelper.c:101
  public function
  VM_CALLEE_SETUP_ARG(ret:ByRef, th:RbThread, iseq:RbISeq, orig_argc:int,
                      orig_argv:StackPointer, block:ByRef):void
  {
    if (iseq.arg_simple & 0x01) {
      // simple check
      if (orig_argc != iseq.argc) {
        rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments ("+orig_argc+" for "+iseq.argc+")");
      }
      ret.v = 0;
    }
    else {
      ret.v = vm_callee_setup_arg_complex(th, iseq, orig_argc, orig_argv, block);
    }
  }

  // vm_insnhelper.c:114
  public function
  vm_callee_setup_arg_complex(th:RbThread, iseq:RbISeq, orig_argc:int,
                              orig_argv:StackPointer, block:ByRef):int
  {
    var i:int;
    var m:int = iseq.argc;
    var argc:int = orig_argc;
    var argv:StackPointer = orig_argv.clone();
    var opt_pc:int = 0;

    th.mark_stack_len = argc + iseq.arg_size;

    // mandatory
    if (argc < (m + iseq.arg_post_len)) { // check with post arg
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments ("+argc+" for "+(m+iseq.arg_post_len)+")");
    }

    argv.index += m;
    argc -= m;

    // post arguments
    if (iseq.arg_post_len != 0) {
      if (!(orig_argc < iseq.arg_post_start)) {
        var new_argv:StackPointer = new StackPointer(new Array(argc));
        for (i = 0; i < argc; i++) {
          new_argv.push(argv.get_at(i));
        }
        argv = new_argv;
      }
      for (i = 0; i < iseq.arg_post_len; i++) {
        orig_argv.set_at(iseq.arg_post_start+i, argv.get_at(argc - iseq.arg_post_len+i));
      }
      argc -= iseq.arg_post_len;
    }

    // opt arguments
    if (iseq.arg_opts != 0) {
      rc.error_c.rb_bug("optional arguments not implemented");
    }

    // rest arguments
    if (iseq.arg_rest != -1) {
      rc.error_c.rb_bug("rest arguments not implemented");
    }

    // block arguments
    if (block && iseq.arg_block != -1) {
      var blockval:Value = rc.Qnil;
      var blockptr:RbBlock = block.v;

      if (argc != 0) {
        rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments ("+
                            orig_argc + " for " + (m+iseq.arg_post_len) + ")");
      }

      if (blockptr) {
        // make Proc object
        if (blockptr.proc == null) {
          var proc:RbProc;

          blockval = rc.vm_c.vm_make_proc(th, th.cfp, blockptr, rc.proc_c.rb_cProc);

          proc = rc.vm_c.GetProcPtr(blockval);
          block.v = proc.block;
        }
        else {
          blockval = blockptr.proc;
        }
      }

      orig_argv.set_at(iseq.arg_block, blockval); // Proc or nil
    }

    th.mark_stack_len = 0;

    return opt_pc;
  }

  // vm_insnhelper.c:424
  public function
  vm_setup_method(th:RbThread, cfp:RbControlFrame, argc:int, blockptr:Value,
                  flag:uint, iseqval:Value, recv:Value, klass:RClass):void
  {
    // various checks
    var iseq:RbISeq;
    var opt_pc:int, i:int;
    var rsp:StackPointer = cfp.sp.clone_from_top(argc); // cfp->sp - argc
    var sp:StackPointer;

    //trace("vm_setup_method - sp:" + cfp.sp.index);

    iseq = rc.iseq_c.GetISeqPtr(iseqval);

    var opt_pc_byref:ByRef = new ByRef(opt_pc);
    var block:ByRef = new ByRef(blockptr);
    // TODO: @skipped Check all these for byref
    VM_CALLEE_SETUP_ARG(opt_pc_byref, th, iseq, argc, rsp.clone(), block);
    opt_pc = opt_pc_byref.v;
    blockptr = block.v;

    sp = rsp.clone_down_stack(iseq.arg_size);

    if (!(flag & RbVm.VM_CALL_TAILCALL_BIT)) {

      for (i = 0; i < iseq.local_size - iseq.arg_size; i++) {
        sp.push(rc.Qnil);
      }

      vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_METHOD, recv, blockptr,
                    iseq.iseq_fn, iseq.iseq, opt_pc, sp.clone(), null, 0);

      //cfp.sp = rsp - 1; // recv
      cfp.sp.set_index(rsp.index - 1); // recv

      //trace("vm_setup_method - leaving cfp.sp:" + cfp.sp.index + " th.cfp.sp: " + th.cfp.sp.index);
    }
    else {
      // For a tail call, pop off the current frame NOW, b/c we
      // won't need it when the next frame is done
      var p_rsp:StackPointer;

      th.cfp = th.cfp_stack.pop(); // pop cf

      p_rsp = th.cfp.sp.clone();

      // copy arguments
      for (i = 0; i < (sp.index-rsp.index); i++) {
        p_rsp.set_at(i, rsp.get_at(i));
      }

      sp.popn(rsp.index - p_rsp.index);

      vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_METHOD, recv, blockptr,
                    iseq.iseq_fn, iseq.iseq, 0, sp.clone(), null, 0);

    }


  }


  // vm_insnhelper.c:273
  public function
  call_cfunc(func:Function, recv:Value, len:int, argc:int, argv:StackPointer):Value
  {
    if (len >= 0 && argc != len) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments("+argc+" for "+len+")");
    }

    switch (len) {
      case -2:
        return rc.Qnil;//func.call(this, recv, rb_ary_new4(argc, argv);
      case -1:
        return func.call(this, argc, argv, recv);
      case 0:
        return func.call(this, recv);
      case 1:
        return func.call(this, recv, argv.get_at(0));
      case 2:
        return func.call(this, recv, argv.get_at(0), argv.get_at(1));
      case 3:
        return func.call(this, recv, argv.get_at(0), argv.get_at(1), argv.get_at(2));
      case 4:
        return func.call(this, recv, argv.get_at(0), argv.get_at(1), argv.get_at(2), argv.get_at(3));
      case 5:
        return func.call(this, recv, argv.get_at(0), argv.get_at(1), argv.get_at(2), argv.get_at(3), argv.get_at(4));
      default:
        rc.error_c.rb_raise(rc.error_c.rb_eArgError, "too many arguments("+len+")");
    }
    return rc.Qnil; // not reached
  }

  // vm_insnhelper.c:480
  public function
  vm_call_method(th:RbThread, cfp:RbControlFrame, num:int, blockptr:Value, flag:uint,
                 id:int, mn:Node, recv:Value, klass:RClass):Value
  {
    var val:Value = rc.Qundef;

    if (mn != null) {
      // TODO: @skipped handle private and protected methods
      //if (mn.nd_noex() == 0) {
        var node:Node;

        node = mn.nd_body;

        switch (node.nd_type()) {
          case Node.RUBY_VM_METHOD_NODE: {
            vm_setup_method(th, cfp, num, blockptr, flag, node.nd_body, recv, klass);
            return rc.Qundef;
          }
          case Node.NODE_CFUNC: {
            val = vm_call_cfunc(th, cfp, num, id, recv, mn.nd_clss, flag, node, blockptr);
            break;
          }
          case Node.NODE_ATTRSET:{
            val = rc.variable_c.rb_ivar_set(recv, node.nd_vid, cfp.sp.get_at(-1));
            cfp.sp.popn(2);
            break;
          }
          case Node.NODE_IVAR:{
            if (num != 0) {
              rc.error_c.rb_raise(rc.error_c.rb_eArgError,
                                  "wrong number of arguments ("+num+" for 0)")
            }
            val = rc.variable_c.rb_attr_get(recv, node.nd_vid);
            cfp.sp.popn(1);
            break;
          }
          case Node.NODE_BMETHOD:{
            rc.error_c.rb_bug("bmethod not implemented");
            //var argv:StackPointer = cfp.sp.clone_from_top(num);
            //val = vm_call_bmethod(th, id, node.nd_cval, recv, klass, num, argv, blockptr);
            //cfp.sp.popn(num+1);
            break;
          }
          case Node.NODE_ZSUPER:{
            klass = mn.nd_clss.super_class;
            mn = rc.vm_method_c.rb_method_node(klass, id);
            rc.error_c.rb_bug("super not implemented");
          }

          default:
            rc.error_c.rb_bug("attrset ivar bmethod zsuper");
          // TODO: @skipped handle attrset, ivar, bmethod, zsuper
        }
      //}
    }
    else {
      // method missing
      if (id == rc.id_c.idMethodMissing) {
        rc.error_c.rb_bug("method missing");
      }
      else {
        var stat:int = 0;
        if (flag & RbVm.VM_CALL_VCALL_BIT) {
          stat |= Node.NOEX_VCALL;
        }
        if (flag & RbVm.VM_CALL_SUPER_BIT) {
          stat |= Node.NOEX_SUPER;
        }
        val = vm_method_missing(th, id, recv, num, RbBlock(blockptr), stat);
      }
    }

    return val;
  }

  public function
  STACK_ADDR_FROM_TOP(cfp:RbControlFrame, num:int):StackPointer
  {
    return cfp.sp.clone_from_top(num);
  }

  public function
  POPN(cfp:RbControlFrame, num:int):void
  {
    cfp.sp.popn_destroy(num);
  }

  // vm_insnhelper.c:409
  public function
  vm_method_missing(th:RbThread, id:int, recv:Value, num:int,
                    blockptr:RbBlock, opt:int):Value
  {
    var reg_cfp:RbControlFrame = th.cfp;
    var argv:StackPointer = STACK_ADDR_FROM_TOP(reg_cfp, num+1);
    var val:Value;
    // This does appear to wack the stack at this point, I guess it's appropriate?
    argv.set_at(0, rc.ID2SYM(id));
    th.method_missing_reason = opt;
    th.passed_block = blockptr;
    val = rc.vm_eval_c.rb_funcall2(recv, rc.id_c.idMethodMissing, num + 1, argv);
    POPN(reg_cfp, num + 1);
    return val;
  }

  // vm_insnhelper.c:361
  public function
  vm_call_cfunc(th:RbThread, reg_cfp:RbControlFrame, num:int, id:int,
                recv:Value, klass:RClass, flag:uint, mn:Node, blockptr:Value):Value
  {
    var val:Value;

    // EXEC_EVENT_HOOK(th, RUBY_EVENT_C_CALL, recv, id, klass);
    {
      var cfp:RbControlFrame = vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_CFUNC,
                                             recv, blockptr, null, null, 0,
                                             reg_cfp.sp.clone(), null, 1);
      cfp.method_id = id;
      cfp.method_class = klass;

      //reg_cfp.sp -= num + 1;
      //var argv:Array = reg_cfp.sp.slice(reg_cfp.sp.length-num, reg_cfp.sp.length);
      var argv:StackPointer = reg_cfp.sp.clone_from_top(num);
      reg_cfp.sp.popn(num+1);

      val = call_cfunc(mn.nd_cfnc, recv, mn.nd_argc, num, argv);

      if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
        rc.error_c.rb_bug("cfp consistency error - send");
      }
      vm_pop_frame(th);
    }
    // EXEC_EVENT_HOOK(th, RUBY_EVENT_C_RETURN, recv, id, klass);

    return val;
  }


  // vm_insnhelper.c:209
  public function
  caller_setup_args(th:RbThread, cfp:RbControlFrame, flag:uint, argc:int,
                    blockiseq:RbISeq, block:ByRef):int
  {
    var blockptr:RbBlock;

    if (block) {
      if (flag & RbVm.VM_CALL_ARGS_BLOCKARG_BIT) {
        var po:RbProc;
        var proc:Value;

        proc = cfp.sp.pop();

        if (proc != rc.Qnil) {
          if (!rc.proc_c.rb_obj_is_proc(proc)) {
            var b:Value = rc.object_c.rb_check_convert_type(proc, Value.T_DATA, "Proc", "to_proc");
            if (rc.NIL_P(b) || !rc.proc_c.rb_obj_is_proc(b)) {
              rc.error_c.rb_raise(rc.error_c.rb_eTypeError,
                       "wrong argument type " + rc.variable_c.rb_obj_classname(proc) +
                       " (expected Proc)");
            }
            proc = b;

          }
          po = rc.vm_c.GetProcPtr(proc);
          blockptr = po.block;
          rc.vm_c.RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp).proc = proc;
          block.v = blockptr;
        }
      } else if (blockiseq) {
        blockptr = rc.vm_c.RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp);
        blockptr.block_iseq = blockiseq;
        blockptr.proc = null;
        block.v = blockptr;
      }
    }

    // handle splat args
    // if (flag & RbVm.VM_CALL_ARGS_SPLAT_BIT) {
    // }

    return argc;
  }

  // vm_insnhelper.c:1043
  public function
  vm_get_cvar_base(cref:Node):RClass
  {
    var klass:RClass

    while (cref && cref.nd_next &&
           (rc.NIL_P(cref.nd_clss) ||
           (cref.nd_clss.flags & Value.FL_SINGLETON))) {
      cref = cref.nd_next;

      if (!cref.nd_next) {
        rc.error_c.rb_warn("class variable access from toplevel");
      }
    }

    klass = cref.nd_clss;

    if (rc.NIL_P(klass)) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "no class variables available");
    }
    return klass;
  }


  // vm_insnhelper.c:1065
  public function
  vm_method_search(id:int, klass:RClass, ic:Value):Node
  {
    var mn:Node;

    // check inline method cache

    mn = rc.vm_method_c.rb_method_node(klass, id);

    return mn;
  }

  // vm_insnhelper.c:73
  public function
  vm_pop_frame(th:RbThread):void
  {
    // TODO: profile collection
    //trace("vm_pop_frame() SKIP profile collection");

    //th.cfp = RUBY_VM_PREVIOUS_CONTROL_FRAME(th.cfp);
    th.cfp = th.cfp_stack.pop();
  }

  // vm_insnhelper.c:983
  public function
  vm_get_ev_const(th:RbThread, iseq:RbISeq, orig_klass:Value,
                  id:int, is_defined:Boolean):Value
  {
    var val:Value;

    if (orig_klass == rc.Qnil) {
      // in current lexical scope
      var root_cref:Node = vm_get_cref(iseq, th.cfp.lfp, th.cfp.dfp);
      var cref:Node = root_cref;
      var klass:Value = orig_klass;

      while (cref && cref.nd_next) {
        klass = cref.nd_clss;
        cref = cref.nd_next;

        if (!rc.NIL_P(klass)) {
          // search_continue:
          if (RClass(klass).iv_tbl[id] != undefined) {
            val = RClass(klass).iv_tbl[id];
            if (val == rc.Qundef) {
              // TODO: @skipped autoload classes - can't
              // rb_autoload_load(klass, id);
              // goto search_continue;
            }
            else {
              if (is_defined) {
                return rc.Qtrue;
              }
              else {
                return val;
              }
            }
          }
        }
      }

      klass = root_cref.nd_clss;
      if (rc.NIL_P(klass)) {
        klass = rc.CLASS_OF(th.cfp.self);
      }

      if (is_defined) {
        return rc.variable_c.rb_const_defined(RClass(klass), id) ? rc.Qtrue : rc.Qfalse;
      }
      else {
        return rc.variable_c.rb_const_get(RClass(klass), id);
      }

    }
    else {
      // TODO: @skipped check if namespace
      // vm_check_if_namespace(orig_klass);
      if (is_defined) {
        return rc.variable_c.rb_const_defined_from(RClass(orig_klass), id) ? rc.Qtrue : rc.Qfalse;
      }
      else {
        return rc.variable_c.rb_const_get_from(RClass(orig_klass), id);
      }
    }
  }

  // inshelper.h:126
  public function
  GET_BLOCK_PTR(cfp:RbControlFrame):RbBlock
  {
    return cfp.lfp.get_at(0);
  }

  // vm_insnhelper.c:632
  public function
  block_proc_is_lambda(procval:Value):Boolean
  {
    var proc:RbProc;

    if (procval) {
      proc = rc.vm_c.GetProcPtr(procval);
      return proc.is_lambda;
    }
    else {
      return false;
    }
  }

  // vm_insnhelper.c:803
  public function
  vm_invoke_block(th:RbThread, reg_cfp:RbControlFrame, num:int, flag:int):Value
  {
    var block:RbBlock = GET_BLOCK_PTR(reg_cfp);
    var iseq:RbISeq;
    var argc:int = num;

    if (GET_ISEQ(reg_cfp).local_iseq.type != RbVm.ISEQ_TYPE_METHOD || block == null) {
      rc.vm_c.vm_localjump_error("no block given (yield)", rc.Qnil, 0);
    }

    iseq = RbISeq(block.block_iseq);

    argc = caller_setup_args(th, reg_cfp, flag, argc, null, null);

    if (iseq.BUILTIN_TYPE() != Value.T_NODE) {
      var opt_pc:int;
      var arg_size:int = iseq.arg_size;
      var rsp:StackPointer = reg_cfp.sp.clone_from_top(argc);
      reg_cfp.sp = rsp;

      // TODO: @skipped
      // CHECK_STACK_OVERFLOW(GET_CFP(), iseq->stack_max);
      opt_pc = vm_yield_setup_args(th, iseq, argc, rsp, null,
                                   block_proc_is_lambda(block.proc));

      vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_BLOCK, block.self, block.dfp.clone(),
                    iseq.iseq_fn, iseq.iseq, opt_pc, rsp.clone_down_stack(arg_size),
                    block.lfp.clone(), iseq.local_size - arg_size);

      return rc.Qundef;
    }
    else {
      var val:Value = vm_yield_with_cfunc(th, block, block.self, argc,
                                          STACK_ADDR_FROM_TOP(reg_cfp, argc), null);
      POPN(reg_cfp, argc);
      return val;
    }
  }

  // vm_insnhelper.c:682
  public function
  vm_yield_setup_args(th:RbThread, iseq:RbISeq, orig_argc:int, argv:StackPointer,
                      blockptr:RbBlock, lambda:Boolean):int
  {
    if (lambda) {
      // call as method
      var opt_pc:int;
      var blockref:ByRef = new ByRef(opt_pc);
      var opt_pc_ref:ByRef = new ByRef(blockptr);
      VM_CALLEE_SETUP_ARG(opt_pc_ref, th, iseq, orig_argc, argv, blockref);
      opt_pc = opt_pc_ref.v;
      blockptr = blockref.v;
      return opt_pc;
    }
    else {
      var i:int;
      var argc:int = orig_argc;
      var m:int = iseq.argc;

      th.mark_stack_len = argc;

      if (!(iseq.arg_simple & 0x02) &&
          (m + iseq.arg_post_len) > 0 &&
          argc == 1 && rc.TYPE(argv.get_at(0)) == Value.T_ARRAY) {

          rc.error_c.rb_bug("unimplemented vm_yield_setup_args");
          /*
          var ary:Value = argv.get_at(0);
          th.mark_stack_len = argc = RARRAY_LEN(ary);

          CHECK_STACK_OVERFLOW(th.cfp, argc);

          MEMCPY(argc, RARRAY_PTR(ary), VALUE, argc);
          */
      }

      for (i = argc; i < m; i++) {
        argv.set_at(i, rc.Qnil);
      }

      if (iseq.arg_rest == -1) {
        if (m < argc) {
          // yield 1, 2
          // => {|a| # truncate
          th.mark_stack_len = argc = m;
        }
      }
      else {
        rc.error_c.rb_bug("don't support rest arguments yet");
        // TODO: @skipped
      }

      // {|&b|}
      if (iseq.arg_block != -1) {
        var procval:Value = rc.Qnil;

        if (blockptr) {
          procval = blockptr.proc;
        }

        argv.set_at(iseq.arg_block, procval);
      }

      th.mark_stack_len = 0;
      return 0;



    }
  }

  // vm_insnhelper.c:662
  public function
  vm_yield_with_cfunc(th:RbThread, block:RbBlock,
                      self:Value, argc:int, argv:StackPointer,
                      blockptr:RbBlock):Value
  {
    var ifunc:Node = Node(block.block_iseq);
    var val:Value, arg:Value, blockarg:Value;
    var lambda:Boolean = block_proc_is_lambda(block.proc);

    if (lambda) {
      rc.error_c.rb_bug("Requires array support.");
      //arg = rb_ary_new4(argc, argv);
    }
    else if (argc == 0) {
      arg = rc.Qnil;
    }
    else {
      arg = argv.get_at(0);
    }

    if (blockptr) {
      rc.error_c.rb_bug("Requires vm_make_proc");
      //blockarg = vm_make_proc(th, th.cfp, blockptr, rb_cProc);
    }
    else {
      blockarg = rc.Qnil;
    }

    vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_IFUNC,
                  self, block.dfp.clone(),
                  null, null, 0, th.cfp.sp.clone(),
                  block.lfp.clone(), 1);

    val = ifunc.nd_cfnc.call(this, ifunc.nd_tval, argc, argv, blockarg);

    th.cfp = th.cfp_stack.pop();

    return val;
  }

  // vm_insnhelper.c:1089
  protected function
  vm_search_normal_superclass(klass:Value, recv:Value):Value
  {
    if (klass.BUILTIN_TYPE() == Value.T_CLASS) {
      klass = RClass(klass).super_class;
    }
    else if (klass.BUILTIN_TYPE() == Value.T_MODULE) {
      var k:Value = rc.CLASS_OF(recv);
      while (k) {
        if (k.BUILTIN_TYPE() == Value.T_ICLASS && RBasic(k).klass == klass) {
          klass = RClass(k).super_class;
          break;
        }
        k = RClass(k).super_class;
      }
    }
    return klass;
  }

  // vm_insnhelper.c:1119
  public function
  vm_search_superclass(reg_cfp:RbControlFrame, ip:RbISeq,
                       recv:Value, sigval:Value,
                       idp:ByRef, klassp:ByRef):void
  {
    var id:int;
    var klass:Value;

    while (ip && !ip.klass) {
      ip = ip.parent_iseq;
    }

    if (ip == null) {
      rc.error_c.rb_raise(rc.error_c.rb_eNoMethodError, "super called outside of method");
    }

    id = ip.defined_method_id;

    if (ip != ip.local_iseq) {
      // defined by Module#define_method()
      rc.error_c.rb_bug("not implemented");
    }
    else {
      klass = vm_search_normal_superclass(ip.klass, recv);
    }

    idp.v = id;
    klassp.v = klass;
  }

}
}
