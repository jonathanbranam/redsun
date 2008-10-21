  public function Init_eval():void {
    Init_vm_eval();
    Init_eval_method();

  }

  // eval.c:856
  public function
  rb_obj_call_init(obj:Value, argc:int, argv:Array):void
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

