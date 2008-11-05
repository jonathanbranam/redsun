package ruby.internals
{
public class Vm_eval_c
{
  public var rc:RubyCore;


  import ruby.internals.Node;
  import ruby.internals.StackPointer;

  public function
  Init_vm_eval():void
  {
    //rc.class_c.rb_define_global_function("catch", rb_f_catch, -1);
    //rc.class_c.rb_define_global_function("throw", rb_f_throw, -1);

    //rc.class_c.rb_define_global_function("loop", rb_f_loop, 0);

    //rc.class_c.rb_define_method(rb_cBasicObject, "instance_eval", rb_obj_instance_eval, -1);
    //rc.class_c.rb_define_method(rb_cBasicObject, "instance_exec", rb_obj_instance_exec, -1);
    //rc.class_c.rb_define_private_method(rb_cBasicObject, "method_missing", rb_method_missing, -1);

    rc.class_c.rb_define_method(rc.object_c.rb_cBasicObject, "__send__", rb_f_send, -1);
    rc.class_c.rb_define_method(rc.object_c.rb_mKernel, "send", rb_f_send, -1);
    rc.class_c.rb_define_method(rc.object_c.rb_mKernel, "public_send", rb_f_public_send, -1);

    //rc.class_c.rb_define_method(rb_cModule, "module_exec", rb_mod_module_exec, -1);
    //rc.class_c.rb_define_method(rb_cModule, "class_exec", rb_mod_module_exec, -1);

    //rc.class_c.rb_define_global_function("caller", rb_f_caller, -1);

  }

  // vm_eval.c:354
  public function
  method_missing(obj:Value, id:int, argc:int, argv:StackPointer, call_status:int):Value
  {
    var nargv:StackPointer;

    rc.GET_THREAD().method_missing_reason = call_status;

    if (id == rc.vm_method_c.missing) {
      rb_method_missing(argc, argv, obj);
    } else if (id == rc.ID_ALLOCATOR) {
      rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "allocator undefined for "+rc.variable_c.rb_class2name(RClass(obj)));
    }

    nargv = new StackPointer(new Array(argc+1));
    nargv.set_at(0, rc.ID2SYM(id));
    for (var i:int = 0; i < argc; i++) {
      nargv.set_at(i+1, argv.get_at(i));
    }

    return rb_funcall2(obj, rc.vm_method_c.missing, argc + 1, nargv);
  }

  // vm_eval.c:410
  public function
  rb_funcall2(recv:Value, mid:int, argc:int, argv:StackPointer):Value
  {
    return rb_call(rc.CLASS_OF(recv), recv, mid, argc, argv, Node.CALL_PUBLIC);
  }

  // vm_eval.c:190
  public function
  rb_call0(klass:RClass, recv:Value, mid:int, argc:int,
           argv:StackPointer, scope:int, self:Value):Value
  {
    var body:Node;
    var method:Node;
    var noex:int;
    var id:int = mid;
    var th:RbThread = rc.GET_THREAD();

    // Check method cache

    var idp:ByRef = new ByRef();
    method = rc.vm_method_c.rb_get_method_body(klass, id, idp);
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
  rb_call(klass:RClass, recv:Value, mid:int, argc:int, argv:StackPointer, scope:int):Value
  {
    return rb_call0(klass, recv, mid, argc, argv, scope, rc.Qundef);
  }

  public function
  rb_funcall(recv:Value, mid:int, n:int, ...args):Value
  {
    var argv:StackPointer = new StackPointer(args, 0);
    return rb_call(rc.CLASS_OF(recv), recv, mid, n, argv, Node.CALL_FCALL);
  }

  // vm_eval.c:303
  public function
  rb_method_missing(argc:int, argv:StackPointer, obj:Value):Value
  {
    var id:int;
    var exc:RClass = rc.error_c.rb_eNoMethodError;
    var format:String = null;
    var th:RbThread = rc.GET_THREAD();
    var last_call_status:int = th.method_missing_reason;
    if (argc == 0 || !rc.SYMBOL_P(argv.get_at(0))) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "no id given");
    }

    // TODO: @skip stack_check
    // stack_check();

    id = rc.SYM2ID(argv.get_at(0));

    if (last_call_status & Node.NOEX_PRIVATE) {
      format = "private method '%s' called for %s";
    }
    else if (last_call_status & Node.NOEX_PROTECTED) {
      format = "protected method '%s' called for %s";
    }
    else if (last_call_status & Node.NOEX_VCALL) {
      format = "undefined local variable or method '%s' for %s";
      exc = rc.error_c.rb_eNameError;
    }
    else if (last_call_status & Node.NOEX_SUPER) {
      format = "super: no superclass method '%s' for %s";
    }
    if (!format) {
      format = "undefined method '"+rc.parse_y.rb_id2name(id)+"' for "+rc.string_c.rb_obj_as_string(obj).string
    }

    // TODO: @skipped create class instance of message error - needs array support
    /*
    var n:int = 0;
    var args:Array = new Array(3);
    args[n++] = rb_funcall(rb_const_get(exc, rc.parse_y.rb_intern("message")), "!".charCodeAt(), 3, rb_str_new2(format), obj, argv[0]);
    args[n++] = argv[0];
    if (exc == rb_eNoMethodError) {
      //args[n++] = rb_ary_new4(argc - 1, argv + 1);
    }
    exc = RClass(rb_class_new_instance(n, args, exc));
    */

    th.cfp = th.cfp_stack.pop();
    rc.error_c.rb_raise(exc, format);
    //rb_exc_raise(exc);

    // will not be reached
    return rc.Qnil;
  }

  // vm_eval.c
  public function
  send_internal(argc:int, argv:StackPointer, recv:Value, scope:int):Value
  {
    var vid:Value;
    var self:Value = rc.vm_c.RUBY_VM_PREVIOUS_CONTROL_FRAME(rc.GET_THREAD(), rc.GET_THREAD().cfp).self;
    var th:RbThread = rc.GET_THREAD();

    if (argc == 0) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "no method name given");
    }

    vid = argv.shift();

    return rb_call0(rc.CLASS_OF(recv), recv, rc.string_c.rb_to_id(vid), argc, argv, scope, self);
  }

  public function
  rb_f_send(argc:int, argv:StackPointer, recv:Value):Value
  {
    return send_internal(argc, argv, recv, Node.NOEX_NOSUPER | Node.NOEX_PRIVATE);
  }

  public function
  rb_f_public_send(argc:int, argv:StackPointer, recv:Value):Value
  {
    return send_internal(argc, argv, recv, Node.NOEX_PUBLIC);
  }

  // vm_eval.c:30
  public function
  vm_call0(th:RbThread, klass:RClass, recv:Value, id:int, oid:int,
           argc:int, argv:StackPointer, body:Node, nosuper:int):Value
  {
    var val:Value = rc.Qnil;
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

      rc.vm_c.rb_vm_set_finish_env(th);
      reg_cfp = th.cfp;

      // TODO: @skipped stack check, copying args onto stack");
      /*
      CHECK_STACK_OVERFLOW(reg_cfp, argc+1);
      */

      reg_cfp.sp.push(recv);
      for (i = 0; i < argc; i++) {
        reg_cfp.sp.push(argv.get_at(i));
      }

      rc.vm_insnhelper_c.vm_setup_method(th, reg_cfp, argc, blockptr, 0, iseqval, recv, klass);
      //val = rc.Qundef;
      val = rc.vm_c.vm_eval_body(th);
      break;
    }
    case Node.NODE_CFUNC:
      // TODO: @skipped RUBY C EVENT HOOK");
      //EXEC_EVENT_HOOK(th, RUBY_EVENT_C_CALL, recv, id, klass);
      {
        reg_cfp = th.cfp;
        var cfp:RbControlFrame = rc.vm_insnhelper_c.vm_push_frame(th, null, RbVm.VM_FRAME_MAGIC_CFUNC,
                                               recv, blockptr, null, null, 0,
                                               reg_cfp.sp.clone(), null, 1);
        cfp.method_id = id;
        cfp.method_class = klass;

        val = rc.vm_insnhelper_c.call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);

        if (reg_cfp != th.cfp_stack[th.cfp_stack.length-1]) {
          rc.error_c.rb_bug("cfp consistency error - call0");
          th.cfp = reg_cfp;
        }
        rc.vm_insnhelper_c.vm_pop_frame(th);
      }
      break;
    case Node.NODE_ATTRSET:
      if (argc != 1) {
        rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments ("+argc+
                            " for 1)");
      }
      val = rc.variable_c.rb_ivar_set(recv, body.nd_vid, argv.get_at(0));
      break;
    case Node.NODE_IVAR:
      if (argc != 0) {
        rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments ("+argc+
                            " for 0)")
      }
      val = rc.variable_c.rb_attr_get(recv, body.nd_vid);
      break;
    case Node.NODE_BMETHOD:
      break;
    default:
      rc.error_c.rb_bug("unsupported: vm_call0("+rc.iseq_c.ruby_node_name(body.nd_type())+")");
      break;
    }
    return val;
  }

  // vm_eval.c:482
  public function
  rb_yield_0(argc:int, argv:StackPointer):Value
  {
    return rc.vm_c.vm_yield(rc.GET_THREAD(), argc, argv);
  }

  // vm_eval.c:488
  public function
  rb_yield(val:Value):Value
  {
    if (val == rc.Qundef) {
      return rb_yield_0(0, null);
    }
    else {
      return rb_yield_0(1, new StackPointer([val]));
    }
  }

  // vm_eval.c:571
  public function
  rb_iterate(it_proc:Function, data1:Value, bl_proc:Function, data2:Value):Value
  {
    var state:int;
    var retval:Value = rc.Qnil;
    var node:Node = rc.NEW_IFUNC(bl_proc, data2);
    var th:RbThread = rc.GET_THREAD();
    var cfp:RbControlFrame = th.cfp;

    // TH_PUSH_TAG(th)
    //state = TH_EXEC_TAG()
    if (state == 0) {
    }

    throw new Error("unimplemented");

    return retval;
  }

  // vm_eval.c:640
  public function
  iterate_method(obj:Value):Value
  {
    var arg:IterMethodArg = IterMethodArg(obj);

    return rb_call(rc.CLASS_OF(arg.obj), arg.obj, arg.mid,
                   arg.argc, arg.argv, Node.CALL_FCALL);
  }

  // vm_eval.c:650
  public function
  rb_block_call(obj:Value, mid:int, argc:int, argv:StackPointer,
                bl_proc:Function, data2:Value):Value
  {
    var arg:IterMethodArg = new IterMethodArg();

    arg.obj = obj;
    arg.mid = mid;
    arg.argc = argc;
    arg.argv = argv;
    return rb_iterate(iterate_method, arg, bl_proc, data2);
  }

}

}
  import ruby.internals.StackPointer;
  import ruby.internals.Value;


class IterMethodArg extends Value
{
  public var obj:Value;
  public var mid:int;
  public var argc:int;
  public var argv:StackPointer;
}
