  // vm_method.c:12
  public var __send__:int, object_id:int;
  public var removed:int, singleton_removed:int, undefined_:int, singleton_undefined:int;
  public var eqq:int, each_:int, aref:int, aset:int, match:int, missing:int;
  public var added:int, singleton_added:int;

  public function Init_eval_method():void {
    // TODO: @skipped
    /*
    rb_define_method(rb_mKernel, "respond_to?", obj_respond_to, -1);

    rb_define_private_method(rb_cModule, "remove_method", rb_mod_remove_method, -1);
    rb_define_private_method(rb_cModule, "undef_method", rb_mod_undef_method, -1);
    rb_define_private_method(rb_cModule, "alias_method", rb_mod_alias_method, 2);
    rb_define_private_method(rb_cModule, "public", rb_mod_public, -1);
    rb_define_private_method(rb_cModule, "protected", rb_mod_protected, -1);
    rb_define_private_method(rb_cModule, "private", rb_mod_private, -1);
    rb_define_private_method(rb_cModule, "module_function", rb_mod_modfunc, -1);

    rb_define_method(rb_cModule, "method_defined?", rb_mod_method_defined, 1);
    rb_define_method(rb_cModule, "public_method_defined?", rb_mod_public_method_defined, 1);
    rb_define_method(rb_cModule, "private_method_defined?", rb_mod_private_method_defined, 1);
    rb_define_method(rb_cModule, "protected_method_defined?", rb_mod_protected_method_defined, 1);
    rb_define_method(rb_cModule, "public_class_method", rb_mod_public_method, -1);
    rb_define_method(rb_cModule, "private_class_method", rb_mod_private_method, -1);

    rb_define_singleton_method(rb_vm_top_self(), "public", top_public, -1);
    rb_define_singleton_method(rb_vm_top_self(), "private", top_private, -1);
    */

    object_id = rb_intern_const("object_id");
    __send__ = rb_intern_const("__send__");
    eqq = rb_intern_const("===");
    each_ = rb_intern_const("each");
    aref = rb_intern_const("[]");
    aset = rb_intern_const("[]=");
    match = rb_intern_const("=~");
    missing = rb_intern_const("method_missing");
    added = rb_intern_const("method_added");
    singleton_added = rb_intern_const("singleton_method_added");
    removed = rb_intern_const("method_removed");
    singleton_removed = rb_intern_const("singleton_method_removed");
    undefined_ = rb_intern_const("method_undefined");
    singleton_undefined = rb_intern_const("singleton_method_undefined");

  }

  // vm_method.c:26
  public function ruby_running():Boolean {
    return GET_VM().running;
  }


  // vm_method.c:104
  protected function rb_add_method(klass:RClass, mid:int, node:Node, noex:uint):void {
    if (!klass) {
      klass = rb_cObject;
    }
    if (!klass.is_singleton() &&
      node && node.nd_type() != Node.NODE_ZSUPER &&
      (mid == rb_intern("initialize") || mid == rb_intern("initialize_copy")))
    {
      noex |= Node.NOEX_PRIVATE;
    } else if (klass.is_singleton() && node
      && node.nd_type() == Node.NODE_CFUNC && mid == rb_intern("allocate")) {
        rb_warn("defining "+
          rb_class2name(rb_iv_get(klass, "__attached__"))+
          ".allocate is deprecated; use rb_define_alloc_func()");
        mid = ID_ALLOCATOR;
    }
    if (klass.is_frozen()) {
      rb_error_frozen("class/module");
    }
    // TODO: @skipped
    //rb_clear_cache_by_id(mid);

    var body:Node;

    if (node) {
      body = NEW_FBODY(NEW_METHOD(node, klass, NOEX_WITH_SAFE(noex)), null);
    } else {
      body = null;
    }

    // check re-definition

    // TODO @skipped

    klass.m_tbl[mid] = body;

    if (node && mid != ID_ALLOCATOR && ruby_running()) {
      if (klass.is_singleton()) {
        rb_funcall(rb_iv_get(klass, "__attached__"), singleton_added, 1, ID2SYM(mid));
      } else {
        rb_funcall(klass, added, 1, ID2SYM(mid));
      }
    }
  }


  public function
  rb_obj_respond_to(obj:Value, id:int, priv:Boolean):Boolean
  {
    return true;
    // TODO: @skipped
    /*
    var klass:RClass = CLASS_OF(obj);

    if (rb_method_basic_definition_p(klass, idRespond_to)) {
      return rb_method_boundp(klass, id, !priv);
    } else {
      var args:Array = new Array();
      var n:int = 0;
      args[n++] = ID2SYM(id);
      if (priv) {
        args[n++] = Qtrue;
      }
      return RTEST(rb_funcall2(obj, idRespond_to, n, args));
    }
    */
  }

  public function rb_respond_to(obj:Value, id:int):Boolean {
    return rb_obj_respond_to(obj, id, false);
  }

  public function obj_respond_to(argc:int, argv:Array, obj:Value):Value {
    return Qtrue;
    // TODO: @skipped
    /*
    var mid:Value;
    var priv:Value;
    var id:int;

    var midRef:ByRef = new ByRef();
    var privRef:ByRef = new ByRef();

    rb_scan_args(argc, argv, "11", midRef, privRef);
    mid = midRef.v;
    priv = privRef.v;
    id = rb_to_id(mid);
    if (rb_method_boundp(CLASS_OF(obj), id, !RTEST(priv))) {
      return Qtrue;
    } else {
      return Qfalse;
    }
    */
  }

  // vm_method.c:192
  public function
  rb_define_alloc_func(klass:RClass, func:Function):void
  {
    // TODO: @skipped
    // Check_Type(klass, T_CLASS);
    rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, NEW_CFUNC(func, 0), Node.NOEX_PRIVATE);
  }


  // vm_method.c:220
  public function
  search_method(klass:RClass, id:int, klassp:RClass):Node
  {
    var body:Node = null;

    if (!klass) {
      return null;
    }

    while ((body = klass.m_tbl[id]) == null) {
      klass = klass.super_class;
      if (klass == null) {
        return null;
      }
    }

    return body;
  }

  // vm_method.c:250
  public function
  rb_get_method_body(klass:RClass, id:int, idp:ByRef):Node
  {
    var fbody:Node;
    var body:Node;
    var method:Node;

    fbody = search_method(klass, id, null);
    if (!fbody || fbody.nd_body == null) {
      // TODO: @skipped
      // store empty info in cache
      return null;
    }

    method = fbody.nd_body;

    if (ruby_running()) {
      // TODO: @skipped
      // Store in cache;
      body = method;
    } else {
      body = method;
    }

    if (idp) {
      idp.v = fbody.nd_oid;
    }

    return body;
  }

  // vm_method.c:290
  public function
  rb_method_node(klass:RClass, id:int):Node
  {
    // TODO: @skipped
    // check method cache
    return rb_get_method_body(klass, id, null);
  }



