
  import ruby.internals.RClass;
  import ruby.internals.StackPointer;
  import ruby.internals.Value;


  public var rb_eLocalJumpError:Value;

  public function
  Init_eval():void
  {

    rb_define_private_method(rb_cModule, "append_features", rb_mod_append_features, 1);
    rb_define_private_method(rb_cModule, "extend_object", rb_mod_extend_object, 1);
    rb_define_private_method(rb_cModule, "include", rb_mod_include, -1);

    Init_vm_eval();
    Init_eval_method();

    rb_define_method(rb_mKernel, "extend", rb_obj_extend, -1);

  }

  // eval.c:928
  public function
  rb_obj_extend(argc:int, argv:StackPointer, obj:Value):Value
  {
    var i:int;

    if (argc == 0) {
      rb_raise(rb_eArgError, "wrong number of arguments (0 for 1)");
    }
    for (i = 0; i < argc; i++) {
      Check_Type(argv.get_at(i), Value.T_MODULE);
    }
    while (argc--) {
      rb_funcall(argv.get_at(argc), rb_intern("extend_object"), 1, obj);
      rb_funcall(argv.get_at(argc), rb_intern("extended"), 1, obj);
    }
    return obj;
  }

  // eval.c:819
  public function
  rb_mod_append_features(module:RClass, include_:Value):Value
  {
    switch (TYPE(include_)) {
      case Value.T_CLASS:
      case Value.T_MODULE:
        break;
      default:
        Check_Type(include_, Value.T_CLASS);
        break;
    }
    rb_include_module(RClass(include_), module);

    return module;
  }

  // eval.c:863
  public function
  rb_extend_object(obj:Value, module:Value):void
  {
    rb_include_module(rb_singleton_class(obj), module);
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
  rb_mod_include(argc:int, argv:StackPointer, module:RClass):Value
  {
    var i:int;

    for (i = 0; i < argc; i++) {
      Check_Type(argv.get_at(i), Value.T_MODULE);
    }

    while (argc--) {
      rb_funcall(argv.get_at(argc), rb_intern("append_features"), 1, module);
      rb_funcall(argv.get_at(argc), rb_intern("included"), 1, module);
    }

    return module;
  }

  // eval.c:856
  public function
  rb_obj_call_init(obj:Value, argc:int, argv:StackPointer):void
  {
    // TODO: @skipped pass passed block
    // PASS_PASSED_BLOCK();
    rb_funcall2(obj, idInitialize, argc, argv);
  }

  // eval.c:48
  public function ruby_init():void {
    // TODO: @skipped Init_stack()
    //Init_stack(&state);
    Init_BareVM();
    Init_heap();
    rb_call_inits();
    ruby_prog_init();

    GET_VM().running = true;
  }


  // eval.c:424
  public function
  rb_exc_raise(mesg:Value):void
  {
    throw new RTag(RTag.TAG_RAISE, mesg);
  }

  // eval.c:233
  public function
  ruby_run_node(n:Value):void
  {
    // TODO: @skipped
    // Init_stack(n);
    ruby_cleanup(ruby_exec_node(n, null));
  }

  // eval.c:141
  public function
  ruby_cleanup(ex:int):int
  {
    // TODO: @skipped
    // cleanup, GC, stop threads, error hanlding
    return ex;
  }

  // eval.c:207
  public function
  ruby_exec_node(n:Value, file:String):int
  {
    var iseq:Value = n;
    var th:RbThread = GET_THREAD();

    // TODO: @skipped PUSH_TAG, EXEC_TAG, POP_TAG");
    th.base_block = null;
    rb_iseq_eval(iseq);
    return 0;
  }

