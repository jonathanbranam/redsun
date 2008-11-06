package ruby.internals
{
public class Vm_method_c
{
  public var rc:RubyCore;



  // vm_method.c:12
  import ruby.internals.StackPointer;

  public var __send__:int, object_id:int;
  public var removed:int, singleton_removed:int, undefined_:int, singleton_undefined:int;
  public var eqq:int, each_:int, aref:int, aset:int, match:int, missing:int;
  public var added:int, singleton_added:int;

  public function Init_eval_method():void {
    // TODO: @skipped
    rc.class_c.rb_define_method(rc.object_c.rb_mKernel, "respond_to?", obj_respond_to, -1);
    rc.class_c.rb_define_private_method(rc.object_c.rb_cModule, "alias_method", rb_mod_alias_method, 2);
    /*

    class_c.rb_define_private_method(rb_cModule, "remove_method", rb_mod_remove_method, -1);
    class_c.rb_define_private_method(rb_cModule, "undef_method", rb_mod_undef_method, -1);
    class_c.rb_define_private_method(rb_cModule, "public", rb_mod_public, -1);
    class_c.rb_define_private_method(rb_cModule, "protected", rb_mod_protected, -1);
    class_c.rb_define_private_method(rb_cModule, "private", rb_mod_private, -1);
    class_c.rb_define_private_method(rb_cModule, "module_function", rb_mod_modfunc, -1);

    class_c.rb_define_method(rb_cModule, "method_defined?", rb_mod_method_defined, 1);
    class_c.rb_define_method(rb_cModule, "public_method_defined?", rb_mod_public_method_defined, 1);
    class_c.rb_define_method(rb_cModule, "private_method_defined?", rb_mod_private_method_defined, 1);
    class_c.rb_define_method(rb_cModule, "protected_method_defined?", rb_mod_protected_method_defined, 1);
    class_c.rb_define_method(rb_cModule, "public_class_method", rb_mod_public_method, -1);
    class_c.rb_define_method(rb_cModule, "private_class_method", rb_mod_private_method, -1);

    rb_define_singleton_method(rb_vm_top_self(), "public", top_public, -1);
    rb_define_singleton_method(rb_vm_top_self(), "private", top_private, -1);
    */

    object_id = rc.parse_y.rb_intern_const("object_id");
    __send__ = rc.parse_y.rb_intern_const("__send__");
    eqq = rc.parse_y.rb_intern_const("===");
    each_ = rc.parse_y.rb_intern_const("each");
    aref = rc.parse_y.rb_intern_const("[]");
    aset = rc.parse_y.rb_intern_const("[]=");
    match = rc.parse_y.rb_intern_const("=~");
    missing = rc.parse_y.rb_intern_const("method_missing");
    added = rc.parse_y.rb_intern_const("method_added");
    singleton_added = rc.parse_y.rb_intern_const("singleton_method_added");
    removed = rc.parse_y.rb_intern_const("method_removed");
    singleton_removed = rc.parse_y.rb_intern_const("singleton_method_removed");
    undefined_ = rc.parse_y.rb_intern_const("method_undefined");
    singleton_undefined = rc.parse_y.rb_intern_const("singleton_method_undefined");

  }

  // vm_method.c:26
  public function
  ruby_running():Boolean
  {
    return rc.GET_VM().running;
  }


  // vm_method.c:104
  public function
  rb_add_method(klass:RClass, mid:int, node:Node, noex:uint):void
  {
    if (!klass) {
      klass = rc.object_c.rb_cObject;
    }
    if (!klass.is_singleton() &&
      node && node.nd_type() != Node.NODE_ZSUPER &&
      (mid == rc.parse_y.rb_intern("initialize") || mid == rc.parse_y.rb_intern("initialize_copy")))
    {
      noex |= Node.NOEX_PRIVATE;
    } else if (klass.is_singleton() && node
      && node.nd_type() == Node.NODE_CFUNC && mid == rc.parse_y.rb_intern("allocate")) {
        rc.error_c.rb_warn("defining "+
          rc.variable_c.rb_class2name(rc.variable_c.rb_iv_get(klass, "__attached__"))+
          ".allocate is deprecated; use rb_define_alloc_func()");
        mid = rc.ID_ALLOCATOR;
    }
    if (klass.is_frozen()) {
      rc.error_c.rb_error_frozen("class/module");
    }
    // TODO: @skipped
    //rb_clear_cache_by_id(mid);

    var body:Node;

    if (node) {
      body = rc.NEW_FBODY(rc.NEW_METHOD(node, klass, rc.NOEX_WITH_SAFE(noex)), 0);
    } else {
      body = null;
    }

    // check re-definition

    // TODO @skipped

    klass.m_tbl[mid] = body;

    if (node && mid != rc.ID_ALLOCATOR && ruby_running()) {
      if (klass.is_singleton()) {
        rc.vm_eval_c.rb_funcall(rc.variable_c.rb_iv_get(klass, "__attached__"),
                                singleton_added, 1, rc.ID2SYM(mid));
      } else {
        rc.vm_eval_c.rb_funcall(klass, added, 1, rc.ID2SYM(mid));
      }
    }
  }

  // vm_mehod.c:1049
  public function
  rb_method_basic_definition_p(klass:RClass, id:int):Boolean
  {
    var node:Node = rb_method_node(klass, id);
    if (node && (node.nd_noex & Node.NOEX_BASIC)) {
      return true;
    }
    return false;
  }

  public function
  rb_obj_respond_to(obj:Value, id:int, priv:Boolean):Boolean
  {
    var klass:RClass = rc.CLASS_OF(obj);

    if (rb_method_basic_definition_p(klass, rc.id_c.idRespond_to)) {
      return rb_method_boundp(klass, id, !priv);
    } else {
      var args:StackPointer = new StackPointer();
      var n:int = 0;
      args.set_at(n++, rc.ID2SYM(id));
      if (priv) {
        args.set_at(n++, rc.Qtrue);
      }
      return rc.RTEST(rc.vm_eval_c.rb_funcall2(obj, rc.id_c.idRespond_to, n, args));
    }
  }

  public function
  rb_respond_to(obj:Value, id:int):Boolean
  {
    return rb_obj_respond_to(obj, id, false);
  }

  public function obj_respond_to(argc:int, argv:StackPointer, obj:Value):Value {
    var mid:Value;
    var priv:Value;
    var id:int;

    //rb_scan_args(argc, argv, "11", midRef, privRef);
    mid = argv.get_at(0);
    priv = argv.get_at(1);
    id = rc.string_c.rb_to_id(mid);
    if (rb_method_boundp(rc.CLASS_OF(obj), id, !rc.RTEST(priv))) {
      return rc.Qtrue;
    }
    return rc.Qfalse;
  }

  // vm_method.c:192
  public function
  rb_define_alloc_func(klass:RClass, func:Function):void
  {
    // TODO: @skipped
    // Check_Type(klass, T_CLASS);
    rb_add_method(rc.class_c.rb_singleton_class(klass), rc.ID_ALLOCATOR, rc.NEW_CFUNC(func, 0), Node.NOEX_PRIVATE);
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

  // vm_method.c:415
  public function
  rb_method_boundp(klass:RClass, id:int, ex:Boolean):Boolean
  {
    var method:Node;

    if ((method = rb_method_node(klass, id)) != null) {
      if (ex && (method.nd_noex & Node.NOEX_PRIVATE)) {
        return false;
      }
      return true;
    }
    return false;
  }

  // vm_method.c:429
  public function
  rb_attr(klass:RClass, id:int, read:Boolean, write:Boolean, ex:Boolean):void
  {
    var name:String;
    var attriv:int;
    var noex:int;

    if (!ex) {
      noex = Node.NOEX_PUBLIC;
    }
    else {
      if (rc.SCOPE_TEST(Node.NOEX_PRIVATE)) {
        noex = Node.NOEX_PRIVATE;
        rc.error_c.rb_warning(rc.SCOPE_CHECK(Node.NOEX_MODFUNC) ?
                              "attribute accessor as module_function" :
                              "private attribute?");
      }
      else if (rc.SCOPE_TEST(Node.NOEX_PROTECTED)) {
        noex = Node.NOEX_PROTECTED;
      }
      else {
        noex = Node.NOEX_PUBLIC;
      }
    }

    if (!rc.parse_y.rb_is_local_id(id) && !rc.parse_y.rb_is_const_id(id)) {
      rc.error_c.rb_name_error(id, "invalid attribute name '"+rc.parse_y.rb_id2name(id) + "'");
    }
    name = rc.parse_y.rb_id2name(id);
    if (!name) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "argument needs to be a symbol or string");
    }
    attriv = rc.parse_y.rb_intern("@"+name);
    if (read) {
      rb_add_method(klass, id, rc.NEW_IVAR(attriv), noex);
    }
    if (write) {
      rb_add_method(klass, rc.parse_y.rb_id_attrset(id), rc.NEW_ATTRSET(attriv), noex);
    }
  }

  // vm_method:727
  public function
  rb_alias(klass:RClass, name:int, def:int):void
  {
    var orig_fbody:Node, node:Node;
    var singleton:Value;
    var data:*;

    // TODO: @skipped frozen check
    //rc.eval_c.rb_frozen_class_p(klass);
    if (klass == rc.object_c.rb_cObject) {
      //rb_secure(4);
    }
    orig_fbody = search_method(klass, def, null);
    if (!orig_fbody || !orig_fbody.nd_body) {
      if (rc.TYPE(klass) == Value.T_MODULE) {
        orig_fbody = search_method(rc.object_c.rb_cObject, def, null);
      }
    }
    if (!orig_fbody || !orig_fbody.nd_body) {
      // TODO: @skipped print undef
      rc.error_c.rb_bug("undefined method");
      //rb_print_undef(klass, def, null);
    }
    if (klass.flags & Value.FL_SINGLETON) {
      singleton = rc.variable_c.rb_iv_get(klass, "__attached__");
    }

    orig_fbody.nd_cnt = orig_fbody.nd_cnt + 1;

    if (klass.iv_tbl[name] != undefined) {
      data = klass.iv_tbl[name];
      node = data;
      if (node) {
        if (rc.RTEST(rc.ruby_verbose()) && node.nd_cnt == 0 && node.nd_body) {
          rc.error_c.rb_warning("discarding old "+rc.parse_y.rb_id2name(name));
        }
        if (Node(Node(node.nd_body).nd_body).nd_type() == Node.NODE_CFUNC) {
          rc.vm_c.rb_vm_check_redefinition_opt_method(node);
        }
      }
    }

    var orig_nd_body:Node = orig_fbody.nd_body;
    klass.m_tbl[name] = rc.NEW_FBODY(
        rc.NEW_METHOD(orig_nd_body.nd_body, orig_nd_body.nd_clss,
                      rc.NOEX_WITH_SAFE(orig_nd_body.nd_noex)), def);

    // TODO: @skipped method caching
    //rb_clear_cache_by_id(name);

    if (!ruby_running()) return;

    if (singleton != null) {
      rc.vm_eval_c.rb_funcall(singleton, singleton_added, 1, rc.ID2SYM(name));
    }
    else {
      rc.vm_eval_c.rb_funcall(klass, added, 1, rc.ID2SYM(name));
    }
  }

  // vm_method.c:805
  public function
  rb_mod_alias_method(mod:RClass, newname:Value, oldname:Value):Value
  {
    rb_alias(mod, rc.string_c.rb_to_id(newname), rc.string_c.rb_to_id(oldname));
    return mod;
  }



}
}
