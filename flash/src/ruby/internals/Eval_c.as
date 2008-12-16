package ruby.internals
{
public class Eval_c
{
  import ruby.internals.RClass;
  import ruby.internals.StackPointer;
  import ruby.internals.Value;

  public var rc:RubyCore;

  public var rb_eLocalJumpError:RClass;
  public var rb_eSysStackError:RClass;

  public function
  Init_eval():void
  {
    /* TODO: fix position */
    /*
    GET_THREAD()->vm->mark_object_ary = rb_ary_new();

    rb_define_virtual_variable("$@", errat_getter, errat_setter);
    rb_define_virtual_variable("$!", errinfo_getter, 0);

    rb_define_global_function("eval", rb_f_eval, -1);
    rb_define_global_function("iterator?", rb_f_block_given_p, 0);
    rb_define_global_function("block_given?", rb_f_block_given_p, 0);
    */

    rc.class_c.rb_define_global_function("raise", rb_f_raise, -1);
    rc.class_c.rb_define_global_function("fail", rb_f_raise, -1);

    /*
    rb_define_global_function("global_variables", rb_f_global_variables, 0);	/ * in variable.c * /
    rb_define_global_function("local_variables", rb_f_local_variables, 0);

    rb_define_global_function("__method__", rb_f_method_name, 0);
    rb_define_global_function("__callee__", rb_f_method_name, 0);
    */

    rc.class_c.rb_define_private_method(rc.object_c.rb_cModule, "append_features", rb_mod_append_features, 1);
    rc.class_c.rb_define_private_method(rc.object_c.rb_cModule, "extend_object", rb_mod_extend_object, 1);
    rc.class_c.rb_define_private_method(rc.object_c.rb_cModule, "include", rb_mod_include, -1);

    rc.vm_eval_c.Init_vm_eval();
    rc.vm_method_c.Init_eval_method();

    rc.class_c.rb_define_singleton_method(rc.vm_c.rb_vm_top_self(), "include", top_include, -1);

    rc.class_c.rb_define_method(rc.object_c.rb_mKernel, "extend", rb_obj_extend, -1);

  }

  // eval.c:468
  public function
  rb_f_raise(argc:int, argv:StackPointer, recv:Value):Value
  {
    var err:Value;

    if (argc == 0) {
      trace("raise with zero arguments is not implemented");
      argc = 1;
      argv = new StackPointer([rc.string_c.rb_str_new("Raise called without argument")]);
      /*
      err = get_errinfo();
      if (!rc.NIL_P(err)) {
        argc = 1;
        argv = new StackPointer([err]);
      }
      */
    }
    rb_raise_jump(rb_make_exception(argc, argv));

    return rc.Qnil; // not reached
  }

  // eval.c:483
  public function
  rb_make_exception(argc:int, argv:StackPointer):Value
  {
    if (argc == 1 && rc.TYPE(argv.get_at(0)) == Value.T_STRING) {
      return rc.error_c.rb_exc_new3(rc.error_c.rb_eRuntimeError, argv.get_at(0));
    } else {
      trace("rb_make_exception: doesn't handle this case yet.");
      return rc.error_c.rb_exc_new3(rc.error_c.rb_eRuntimeError,
        rc.string_c.rb_str_new("rb_make_exception: doesn't handle this case yet."));
    }
  }

  // eval.c:529
  public function
  rb_raise_jump(mesg:Value):void
  {
    var th:RbThread = rc.GET_THREAD();
    th.cfp = th.cfp_stack.pop();
    /* TODO: fix me */
    rb_longjmp(RTag.TAG_RAISE, mesg);
  }

  // eval.c:544
  public function
  rb_block_given_p():Boolean
  {
    var th:RbThread = rc.GET_THREAD();

    // magic pointer arithmetic here
    if (th.cfp.lfp.get_at(0) is RbBlock) {
      return true;
    }
    else {
      return false;
    }
  }

  // eval.c:954
  protected function
  top_include(argc:int, argv:StackPointer, self:Value):Value
  {
    var th:RbThread = rc.GET_THREAD();

    // TODO: @skipped
    // rb_secure(4);
    if (th.top_wrapper) {
      rc.error_c.rb_warning("main#include in the wrapped load is effective only in wrapper module");
      return rb_mod_include(argc, argv, th.top_wrapper);
    }
    return rb_mod_include(argc, argv, rc.object_c.rb_cObject);
  }

  // eval.c:928
  public function
  rb_obj_extend(argc:int, argv:StackPointer, obj:Value):Value
  {
    var i:int;

    if (argc == 0) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "wrong number of arguments (0 for 1)");
    }
    for (i = 0; i < argc; i++) {
      rc.Check_Type(argv.get_at(i), Value.T_MODULE);
    }
    while (argc--) {
      rc.vm_eval_c.rb_funcall(argv.get_at(argc), rc.parse_y.rb_intern("extend_object"), 1, obj);
      rc.vm_eval_c.rb_funcall(argv.get_at(argc), rc.parse_y.rb_intern("extended"), 1, obj);
    }
    return obj;
  }

  // eval.c:819
  public function
  rb_mod_append_features(module:RClass, include_:Value):Value
  {
    switch (rc.TYPE(include_)) {
      case Value.T_CLASS:
      case Value.T_MODULE:
        break;
      default:
        rc.Check_Type(include_, Value.T_CLASS);
        break;
    }
    rc.class_c.rb_include_module(RClass(include_), module);

    return module;
  }

  // eval.c:863
  public function
  rb_extend_object(obj:Value, module:Value):void
  {
    rc.class_c.rb_include_module(rc.class_c.rb_singleton_class(obj), module);
  }

  // eval.c:896
  public function
  rb_mod_extend_object(mod:Value, obj:Value):Value
  {
    rb_extend_object(obj, mod);
    return obj;
  }

  // eval.c:842
  public function
  rb_mod_include(argc:int, argv:StackPointer, module:Value):Value
  {
    var i:int;

    for (i = 0; i < argc; i++) {
      rc.Check_Type(argv.get_at(i), Value.T_MODULE);
    }

    while (argc--) {
      rc.vm_eval_c.rb_funcall(argv.get_at(argc), rc.parse_y.rb_intern("append_features"), 1, module);
      rc.vm_eval_c.rb_funcall(argv.get_at(argc), rc.parse_y.rb_intern("included"), 1, module);
    }

    return module;
  }

  // eval.c:856
  public function
  rb_obj_call_init(obj:Value, argc:int, argv:StackPointer):void
  {
    rc.PASS_PASSED_BLOCK();
    rc.vm_eval_c.rb_funcall2(obj, rc.id_c.idInitialize, argc, argv);
  }

  // eval.c:48
  public function ruby_init():void {
    // TODO: @skipped Init_stack()
    //Init_stack(&state);
    rc.vm_c.Init_BareVM();
    rc.gc_c.Init_heap();
    rc.rb_call_inits();
    rc.ruby_prog_init();

    rc.GET_VM().running = true;
  }


  // eval.c:349
  public function
  rb_longjmp(tag:int, mesg:Value):void
  {
    var th:RbThread = rc.GET_THREAD();

    // LOTS OF CODE HERE

    if (rc.NIL_P(mesg)) {
      mesg = th.errinfo;
    }
    if (rc.NIL_P(mesg)) {
      mesg = rc.error_c.rb_exc_new(rc.error_c.rb_eRuntimeError, null);
    }

    if (!rc.NIL_P(mesg)) {
      th.errinfo = mesg;
    }

    // LOTS OF DEBUGGING CODE HERE

    throw new RTag(tag, mesg);
  }

  // eval.c:424
  public function
  rb_exc_raise(mesg:Value):void
  {
    rb_longjmp(RTag.TAG_RAISE, mesg);
  }

  // eval.c:233
  public function
  ruby_run_node(n:Value):int
  {
    // TODO: @skipped
    // Init_stack(n);
    return ruby_cleanup(ruby_exec_node(n, null));
  }

  // eval.c:141
  public function
  ruby_cleanup(ex:int):int
  {
    // TODO: @skipped
    // cleanup, GC, stop threads, error hanlding

    if (ex != 0) {
      trace("Ruby exited with abnormal status.");
      var errinfo:Value = rc.GET_THREAD().errinfo;
      trace(""+errinfo);
      //trace("klass: " + );
    }
    return ex;
  }

  // eval.c:207
  public function
  ruby_exec_node(n:Value, file:String):int
  {
    var state:int;
    var iseq:Value = n;
    var th:RbThread = rc.GET_THREAD();

    // TODO: @skipped PUSH_TAG, EXEC_TAG, POP_TAG");
    var tag:RbVmTag = rc.PUSH_TAG(th);
    try { // EXEC_TAG()
      // state = EXEC_TAG();
      // TODO: @skip SAVE_ROOT_JMPBUF
      th.base_block = null;
      rc.vm_c.rb_iseq_eval(iseq);
    } catch (e:RTag) {
      // state
      state = e.tag;
    }
    rc.POP_TAG(tag, th);
    return state;
  }

}
}
