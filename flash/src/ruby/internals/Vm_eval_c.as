
  import ruby.internals.Node;

  public function
  Init_vm_eval():void
  {
    //rb_define_global_function("catch", rb_f_catch, -1);
    //rb_define_global_function("throw", rb_f_throw, -1);

    //rb_define_global_function("loop", rb_f_loop, 0);

    //rb_define_method(rb_cBasicObject, "instance_eval", rb_obj_instance_eval, -1);
    //rb_define_method(rb_cBasicObject, "instance_exec", rb_obj_instance_exec, -1);
    //rb_define_private_method(rb_cBasicObject, "method_missing", rb_method_missing, -1);

    rb_define_method(rb_cBasicObject, "__send__", rb_f_send, -1);
    rb_define_method(rb_mKernel, "send", rb_f_send, -1);
    rb_define_method(rb_mKernel, "public_send", rb_f_public_send, -1);

    //rb_define_method(rb_cModule, "module_exec", rb_mod_module_exec, -1);
    //rb_define_method(rb_cModule, "class_exec", rb_mod_module_exec, -1);

    //rb_define_global_function("caller", rb_f_caller, -1);

  }

  // vm_eval.c:354
  public function
  method_missing(obj:Value, id:int, argc:int, argv:Array, call_status:int):Value
  {
    var nargv:Array;

    GET_THREAD().method_missing_reason = call_status;

    if (id == missing) {
      rb_method_missing(argc, argv, obj);
    } else if (id == ID_ALLOCATOR) {
      rb_raise(rb_eTypeError, "allocator undefined for "+rb_class2name(RClass(obj)));
    }

    nargv = new Array(argc+1);
    nargv[0] = ID2SYM(id);
    for (var i:int = 0; i < argv.length; i++) {
      nargv[i+1] = argv[i];
    }

    return rb_funcall2(obj, missing, argc + 1, nargv);
  }

  // vm_eval.c:410
  public function
  rb_funcall2(recv:Value, mid:int, argc:int, argv:Array):Value
  {
    return rb_call(CLASS_OF(recv), recv, mid, argc, argv, Node.CALL_PUBLIC);
  }

  // vm_eval.c:190
  public function
  rb_call0(klass:RClass, recv:Value, mid:int, argc:int,
           argv:Array, scope:int, self:Value):Value
  {
    var body:Node;
    var method:Node;
    var noex:int;
    var id:int = mid;
    var th:RbThread = GET_THREAD();

    // Check method cache

    var idp:ByRef = new ByRef();
    method = rb_get_method_body(klass, id, idp);
    if (method) {
      noex = method.nd_noex;
      klass = method.nd_clss;
      body = method.nd_body;
      id = idp.v;
    } else {
      if (scope == 3) {
        return method_missing(recv, mid, argc, argv, Node.NOEX_SUPER);
      } else {
        return method_missing(recv, mid, argc, argv, scope == 2 ? Node.NOEX_VCALL : 0);
      }
    }

    // Various error condition checks

    return vm_call0(th, klass, recv, mid, id, argc, argv, body, noex & Node.NOEX_NOSUPER);
  }

  public function
  rb_call(klass:RClass, recv:Value, mid:int, argc:int, argv:Array, scope:int):Value
  {
    return rb_call0(klass, recv, mid, argc, argv, scope, Qundef);
  }

  public function
  rb_funcall(recv:Value, mid:int, n:int, ...argv):Value
  {
    return rb_call(CLASS_OF(recv), recv, mid, n, argv, Node.CALL_FCALL);
  }

  // vm_eval.c:303
  public function
  rb_method_missing(argc:int, argv:Array, obj:Value):Value
  {
    var id:int;
    var exc:RClass = rb_eNoMethodError;
    var format:String = null;
    var th:RbThread = GET_THREAD();
    var last_call_status:int = th.method_missing_reason;
    if (argc == 0 || !SYMBOL_P(argv[0])) {
      rb_raise(rb_eArgError, "no id given");
    }

    // TODO: @skip stack_check
    // stack_check();

    id = SYM2ID(argv[0]);

    if (last_call_status & Node.NOEX_PRIVATE) {
      format = "private method '%s' called for %s";
    }
    else if (last_call_status & Node.NOEX_PROTECTED) {
      format = "protected method '%s' called for %s";
    }
    else if (last_call_status & Node.NOEX_VCALL) {
      format = "undefined local variable or method '%s' for %s";
      exc = rb_eNameError;
    }
    else if (last_call_status & Node.NOEX_SUPER) {
      format = "super: no superclass method '%s' for %s";
    }
    if (!format) {
      format = "undefined method '"+rb_obj_as_string(obj)+"' for "+rb_id2name(id);
    }

    // TODO: @skipped create class instance of message error - needs array support
    /*
    var n:int = 0;
    var args:Array = new Array(3);
    args[n++] = rb_funcall(rb_const_get(exc, rb_intern("message")), "!".charCodeAt(), 3, rb_str_new2(format), obj, argv[0]);
    args[n++] = argv[0];
    if (exc == rb_eNoMethodError) {
      //args[n++] = rb_ary_new4(argc - 1, argv + 1);
    }
    exc = RClass(rb_class_new_instance(n, args, exc));
    */

    th.cfp = th.cfp_stack.pop();
    rb_raise(exc, format);
    //rb_exc_raise(exc);

    // will not be reached
    return Qnil;
  }

  // vm_eval.c
  public function
  send_internal(argc:int, argv:Array, recv:Value, scope:int):Value
  {
    var vid:Value;
    var self:Value = RUBY_VM_PREVIOUS_CONTROL_FRAME(GET_THREAD(), GET_THREAD().cfp).self;
    var th:RbThread = GET_THREAD();

    if (argc == 0) {
      rb_raise(rb_eArgError, "no method name given");
    }

    vid = argv.shift();

    return rb_call0(CLASS_OF(recv), recv, rb_to_id(vid), argc, argv, scope, self);
  }

  public function
  rb_f_send(argc:int, argv:Array, recv:Value):Value
  {
    return send_internal(argc, argv, recv, Node.NOEX_NOSUPER | Node.NOEX_PRIVATE);
  }

  public function
  rb_f_public_send(argc:int, argv:Array, recv:Value):Value
  {
    return send_internal(argc, argv, recv, Node.NOEX_PUBLIC);
  }

  // vm_eval.c:30
  public function
  vm_call0(th:RbThread, klass:RClass, recv:Value, id:int, oid:int,
           argc:int, argv:Array, body:Node, nosuper:int):Value
  {
    var val:Value = Qnil;
    var blockptr:RbBlock;

    if (th.passed_block) {
      blockptr = th.passed_block;
      th.passed_block = null;
    }

    var type:uint = body.nd_type();

    // shared vars:
    var reg_cfp:RbControlFrame;

    switch (type) {
    case Node.RUBY_VM_METHOD_NODE:{
      var iseqval:Value = body.nd_body;
      var i:int;

      rb_vm_set_finish_env(th);
      reg_cfp = th.cfp;

      // TODO: @skipped stack check, copying args onto stack");
      /*
      CHECK_STATCK_OVERFLOW(reg_cfp, argc+1);

      *reg_cfp.sp++ = recv;
      for (i = 0; i < argc; i++) {
        *reg_cfp.sp++ = argv[i];
      }
      */

      vm_setup_method(th, reg_cfp, argc, blockptr, 0, iseqval, recv, klass);
      val = vm_eval_body(th);
      break;
    }
    case Node.NODE_CFUNC:
      // TODO: @skipped RUBY C EVENT HOOK");
      //EXEC_EVENT_HOOK(th, RUBY_EVENT_C_CALL, recv, id, klass);
      {
        reg_cfp = th.cfp;
        var cfp:RbControlFrame = vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_CFUNC,
                                               recv, blockptr, null, reg_cfp.sp, null, 1);
        cfp.method_id = id;
        cfp.method_class = klass;

        val = call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);

        if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
          rb_bug("cfp consistency error - call0");
          th.cfp = reg_cfp;
        }
        vm_pop_frame(th);
      }
      break;
    case Node.NODE_ATTRSET:
      break;
    case Node.NODE_IVAR:
      break;
    case Node.NODE_BMETHOD:
      break;
    default:
      rb_bug("unsupported: vm_call0("+ruby_node_name(body.nd_type())+")");
      break;
    }
    return val;
  }

