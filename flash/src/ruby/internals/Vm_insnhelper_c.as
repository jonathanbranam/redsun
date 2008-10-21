
  import ruby.internals.Node;
  import ruby.internals.RClass;
  import ruby.internals.RbBlock;
  import ruby.internals.RbControlFrame;
  import ruby.internals.RbISeq;
  import ruby.internals.RbThread;
  import ruby.internals.RbVm;
  import ruby.internals.Value;

  public function
  GET_PREV_DFP(dfp:Array):Array
  {
    trace("GET_PREV_DFP THIS IS WRONG!");
    // ((VALUE *)((dfp)[0] & ~0x03))
    return dfp;
  }

  public function
  GET_ISEQ(cfp:RbControlFrame):RbISeq
  {
    return cfp.iseq;
  }

  // vm_insnhelper.c:946
  public function
  vm_get_cref(iseq:RbISeq, lfp:Array, dfp:Array):Node
  {
    var cref:Node = null;

    while (1) {
      if (lfp == dfp) {
        cref = iseq.cref_stack;
        break;
      } else if (dfp[dfp.length-1] != Qnil) {
        cref = dfp[dfp.length-1];
        break;
      }
      dfp = GET_PREV_DFP(dfp);
    }

    if (cref == null) {
      rb_bug("vm_get_cref: unreachable");
    }

    return cref;
  }


  // vm_insnhelper.c:24
  public function
  vm_push_frame(th:RbThread, iseq:RbISeq, type:uint, self:Value, specval:Object,
                pc:Function, sp:Array, lfp:Array, local_size:int):RbControlFrame
  {
    // rb_control_frame_t * const cfp = th->cfp = th->cfp - 1;
    var cfp:RbControlFrame = new RbControlFrame();
    th.cfp_stack.push(th.cfp);
    th.cfp = cfp;
    var i:int;

    for (i = 0; i < local_size; i++) {
      sp[i] = Qnil;
    }

    if (lfp == null) {
      lfp = sp;
    }

    cfp.pc = pc;
    cfp.sp = sp; // sp + 1
    cfp.bp = sp; // sp + 1
    cfp.iseq = iseq;
    cfp.flag = type;
    cfp.self = self;
    cfp.lfp = lfp;
    cfp.dfp = sp;
    cfp.proc = null;

    return cfp;
  }


  // vm_insnhelper.c:424
  public function
  vm_setup_method(th:RbThread, cfp:RbControlFrame, argc:int, blockptr:Value,
                  flag:uint, iseqval:Value, recv:Value, klass:RClass):void
  {
    // various checks
    var iseq:RbISeq;
    var sp:Array = cfp.sp; // cfp->sp - argc
    trace("vm_setup_method() Didn't adjust stack pointer for arg count.");

    iseq = GetISeqPtr(iseqval);

    vm_push_frame(th, iseq, RbVm.VM_FRAME_MAGIC_METHOD, recv, blockptr, iseq.iseq_fn, sp, null, 0);
  }


  // vm_insnhelper.c:273
  public function
  call_cfunc(func:Function, recv:Value, len:int, argc:int, argv:Array):Value
  {
    if (len >= 0 && argc != len) {
      rb_raise(rb_eArgError, "wrong number of arguments("+argc+" for "+len+")");
    }

    switch (len) {
      case -2:
        return Qnil;//func.call(this, recv, rb_ary_new4(argc, argv);
      case -1:
        return func.call(this, argc, argv, recv);
      case 0:
        return func.call(this, recv);
      case 1:
        return func.call(this, recv, argv[0]);
      case 2:
        return func.call(this, recv, argv[0], argv[1]);
      case 3:
        return func.call(this, recv, argv[0], argv[1], argv[2]);
      case 4:
        return func.call(this, recv, argv[0], argv[1], argv[2], argv[3]);
      case 5:
        return func.call(this, recv, argv[0], argv[1], argv[2], argv[3], argv[4]);
      default:
        rb_raise(rb_eArgError, "too many arguments("+len+")");
    }
    return Qnil; // not reached
  }

  // vm_insnhelper.c:480
  public function
  vm_call_method(th:RbThread, cfp:RbControlFrame, num:int, blockptr:Value, flag:uint,
                 id:int, mn:Node, recv:Value, klass:RClass):Value
  {
    var val:Value = Qundef;

    if (mn != null) {
      // TODO: @skipped handle private and protected methods
      //if (mn.nd_noex() == 0) {
        var node:Node;

        node = mn.nd_body;

        switch (node.nd_type()) {
        case Node.RUBY_VM_METHOD_NODE: {
          vm_setup_method(th, cfp, num, blockptr, flag, node.nd_body, recv, klass);
          return Qundef;
        }
        case Node.NODE_CFUNC: {
          val = vm_call_cfunc(th, cfp, num, id, recv, mn.nd_clss, flag, node, blockptr);
        }
        // TODO: @skipped handle attrset, ivar, bmethod, zsuper
        }
      //}
    }
    else {
      // method missing
      if (id == idMethodMissing) {
        rb_bug("method missing");
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
  STACK_ADDR_FROM_TOP(cfp:RbControlFrame, num:int):Array
  {
    return cfp.sp.slice(cfp.sp.length-num);
  }

  public function
  POPN(cfp:RbControlFrame, num:int):void
  {
    cfp.sp.splice(cfp.sp.length-num,num);
  }

  // vm_insnhelper.c:409
  public function
  vm_method_missing(th:RbThread, id:int, recv:Value, num:int,
                    blockptr:RbBlock, opt:int):Value
  {
    var reg_cfp:RbControlFrame = th.cfp;
    var argv:Array = STACK_ADDR_FROM_TOP(reg_cfp, num+1);
    var val:Value;
    // This does appear to wack the stack at this point, I guess it's appropriate?
    argv[0] = ID2SYM(id);
    th.method_missing_reason = opt;
    th.passed_block = blockptr;
    val = rb_funcall2(recv, idMethodMissing, num + 1, argv);
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
                                             recv, blockptr, null, reg_cfp.sp, null, 1);
      cfp.method_id = id;
      cfp.method_class = klass;

      //reg_cfp.sp -= num + 1;
      var argv:Array = reg_cfp.sp.slice(reg_cfp.sp.length-num, reg_cfp.sp.length);
      reg_cfp.sp.length -= num+1;

      val = call_cfunc(mn.nd_cfnc, recv, mn.nd_argc, num, argv);

      if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
        rb_bug("cfp consistency error - send");
      }
      vm_pop_frame(th);
    }
    // EXEC_EVENT_HOOK(th, RUBY_EVENT_C_RETURN, recv, id, klass);

    return val;
  }


  // vm_insnhelper.c:209
  public function
  caller_setup_args(th:RbThread, cfp:RbControlFrame, flag:uint, argc:int,
                    blockiseq:Value, block:ByRef):int
  {
    var blockptr:RbBlock;

    if (block) {
      if (false) { //flag & RbVm.VM_CALL_ARGS_BLOCKARG_BIT) {
        // Handle dispatching to a proc
        /*
        var po:RbProc;
        var proc:Value;

        proc = cfp.sp.pop();

        if (proc != Qnil) {
          if (!rb_obj_is_proc(proc)) {

          }
        }
        */
      } else if (blockiseq) {
        blockptr = RUBY_VM_GET_BLOCK_PTR_IN_CFP(cfp);
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

  // vm_insnhelper.c:1065
  public function
  vm_method_search(id:int, klass:RClass, ic:Value):Node
  {
    var mn:Node;

    // check inline method cache

    mn = rb_method_node(klass, id);

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

    if (orig_klass == Qnil) {
      // in current lexical scope
      var root_cref:Node = vm_get_cref(iseq, th.cfp.lfp, th.cfp.dfp);
      var cref:Node = root_cref;
      var klass:Value = orig_klass;

      while (cref && cref.nd_next) {
        klass = cref.nd_clss;
        cref = cref.nd_next;

        if (!NIL_P(klass)) {
          // search_continue:
          if (RClass(klass).iv_tbl[id] != undefined) {
            val = RClass(klass).iv_tbl[id];
            if (val == Qundef) {
              // TODO: @skipped autoload classes - can't
              // rb_autoload_load(klass, id);
              // goto search_continue;
            }
            else {
              if (is_defined) {
                return Qtrue;
              }
              else {
                return val;
              }
            }
          }
        }
      }

      klass = root_cref.nd_clss;
      if (NIL_P(klass)) {
        klass = CLASS_OF(th.cfp.self);
      }

      if (is_defined) {
        return rb_const_defined(RClass(klass), id) ? Qtrue : Qfalse;
      }
      else {
        return rb_const_get(RClass(klass), id);
      }

    }
    else {
      // TODO: @skipped check if namespace
      // vm_check_if_namespace(orig_klass);
      if (is_defined) {
        return rb_const_defined_from(RClass(orig_klass), id) ? Qtrue : Qfalse;
      }
      else {
        return rb_const_get_from(RClass(orig_klass), id);
      }
    }
  }

