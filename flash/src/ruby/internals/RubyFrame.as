package ruby.internals
{
public class RubyFrame
{
  public var rc:RubyCore;
  public var th:RbThread;

  public var reg_cfp:RbControlFrame;
  public var reg_sp:StackPointer;

  public var Qnil:Value;
  public var Qfalse:Value;
  public var Qtrue:Value;
  public var Qundef:Value;

  public function RubyFrame(rc:RubyCore, th:RbThread)
  {
    this.rc = rc;
    this.th = th;

    this.Qnil = rc.Qnil;
    this.Qfalse = rc.Qfalse;
    this.Qtrue = rc.Qtrue;
    this.Qundef = rc.Qundef;

    RESTORE_REGS();
  }

  public function
  RESTORE_REGS():void
  {
    reg_cfp = th.cfp;
    reg_sp = reg_cfp.sp;
  }

  public function
  pop():void
  {
    reg_sp.popn(1);
  }

  public function
  dup():void
  {
    var val:* = reg_sp.pop();
    reg_sp.push(val);
    reg_sp.push(val);
  }

  // insns.def:650
  public function
  dupn(n:int):void
  {
    var i:int;
    var sp:StackPointer = reg_sp.clone_from_top(n);
    for (i = 0; i < n; i++) {
      reg_sp.set_at(i, sp.get_at(i));
    }
    reg_sp.inc_index();
  }

  // insns.def:670
  public function
  swap():void
  {
    var obj:Value = reg_sp.pop();
    var val:Value = reg_sp.pop();
    reg_sp.push(obj);
    reg_sp.push(val);
  }

  // insns.def:684
  public function
  reput():void
  {
    var val:Value = reg_sp.pop();
    reg_sp.push(val);
  }

  // insns.def:698
  public function
  topn(n:int):void
  {
    var val:Value = reg_sp.get_at(n);
    reg_sp.push(val);
  }

  // insns.def:712
  public function
  setn(n:int):void
  {
    var val:Value = reg_sp.pop();
    reg_sp.set_topn(n-1, val);
    reg_sp.push(val);
  }

  // insns.def:726
  public function
  adjuststack(n:int):void
  {
    reg_sp.dec(n);
  }

  // insns.def:745
  public function
  defined(type:int, obj:Value, needstr:Value):void
  {
    var v:Value = reg_sp.pop();

    var klass:RClass;
    var expr_type:String;
    var val:Value = rc.Qnil;

    switch (type) {
      /*
      case Vm_insnhelper_c.DEFINED_IVAR:
        if (rc.variable_c.rb_ivar_defined(reg_cfp.self, rc.SYM2ID(obj))) {
          expr_type = "instance-variable";
        }
        break;
      case Vm_insnhelper_c.DEFINED_IVAR2:
        klass = rc.vm_insnhelper_c.vm_get_cbas(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp);
        break;
      case Vm_insnhelper_c.DEFINED_GVAR:
        if (rc.variable_c.rb_gvar_defined(GlobalEntry(obj))) {
          expr_type = "global-variable";
        }
        break;
      case Vm_insnhelper_c.DEFINED_CVAR:
        klass = rc.vm_insnhelper_c.vm_get_cbase(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp);
        if (rc.variable_c.rb_cvar_defined(klass, rc.SYM2ID(obj))) {
          expr_type = "class variable";
        }
        break;
      */
      default:
        rc.error_c.rb_bug("unimplemented defined? type (VM)");
    }
    if (expr_type != null) {
      if (needstr != rc.Qfalse) {
        val = rc.string_c.rb_str_new2(expr_type);
      }
      else {
        val = rc.Qtrue;
      }
    }

    reg_sp.push(val);
  }

  public function
  putnil():void
  {
    reg_sp.push(Qnil);
  }

  public function
  putstring(str:String):void
  {
    reg_sp.push(rc.string_c.rb_str_new(str));
  }

  public function
  putiseq(val:*):void
  {
    var iseqval:Value;
    if (val is Array) {
      iseqval = rc.iseqval_from_array(val);
    } else if (val is RbISeq) {
      iseqval = RbISeq(val).self;
    }
    reg_sp.push(iseqval);
  }

  // insns.def:303
  public function
  putself():void
  {
    var val:Value = reg_cfp.self;
    reg_sp.push(val);
  }

  public function
  putobject(val:*):void
  {
    if (val is String) {
      reg_sp.push(rc.string_c.rb_str_new(val));
    } else if (val is int || val is uint) {
      reg_sp.push(rc.numeric_c.INT2FIX(val));
    } else if (val is Number) {
      reg_sp.push(rc.DOUBLE2NUM(val));
    } else if (val === rc.Qfalse) {
      reg_sp.push(val);
    } else if (val === rc.Qtrue) {
      reg_sp.push(val);
    } else if (val is Value) {
      reg_sp.push(val);
    } else {
      rc.error_c.rb_bug("Unknown object sent to putobject: " + val);
    }
  }

  public function
  putspecialobject(value_type:int):void
  {
    switch (value_type) {
      case RbVm.VM_SPECIAL_OBJECT_VMCORE:
        reg_sp.push(rc.vm_c.rb_mRubyVMFrozenCore);
        break;
      case RbVm.VM_SPECIAL_OBJECT_CBASE:
        reg_sp.push(rc.vm_c.vm_get_cbase(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp));
        break;
      default:
        rc.error_c.rb_bug("putspecialobject insn: unknown value_type: " + value_type);
    }
  }


  public function
  leave():void
  {
    var val:Value = reg_sp.pop();
    //trace("leave retval: " + val);
    if (!reg_sp.equals(reg_cfp.bp)) {
      rc.error_c.rb_bug("Stack consistency error (sp: "+reg_sp+", bp: " +reg_cfp.bp +")");
    }
    // RUBY_VM_CHECK_INTS();
    rc.vm_insnhelper_c.vm_pop_frame(th);
    RESTORE_REGS();
    reg_sp.push(val);
  }

  // insns.def:1077
  public function
  finish():Value
  {
    var val:Value = reg_sp.pop();
    th.cfp = th.cfp_stack.pop();
    return val;
  }

  // insns.def:1100
  public function
  rthrow(throw_state:int):void
  {
    var throwobj:Value = reg_sp.pop();
    var val:Value = rc.Qnil;
    rc.error_c.rb_bug("throw unimplemented");
    // RUBY_VM_CHECK_INTS();
    //val = vm_throw(th, reg_cfp, throw_state, throwobj);
    //THROW_EXCEPTION(val);
    reg_sp.push(val);
  }

  // insns.def:1036
  public function
  invokeblock(num:int, flag:int):void
  {
    var val:Value = rc.vm_insnhelper_c.vm_invoke_block(th, reg_cfp, num, flag);
    if (val == Qundef) {
      RESTORE_REGS();
      // NEXT_INSN();
      return;
    }
    reg_cfp.sp.push(val);
  }

  // insns.def:1007
  public function
  invokesuper(op_argc:int, blockiseq_data:*, op_flag:int):void
  {
    var val:Value;
    var blockptr:RbBlock = !(op_flag & RbVm.VM_CALL_ARGS_BLOCKARG_BIT) ? rc.vm_insnhelper_c.GET_BLOCK_PTR(reg_cfp) : null;
    var blockptr_ref:ByRef = new ByRef(blockptr);

    var blockiseq:RbISeq;
    if (blockiseq_data is Array) {
      // Guessing at this, but it seems to be needed to pass in parent for a block
      var blockiseqval:Value = rc.iseqval_from_array(blockiseq_data, reg_cfp.iseq.self);
      blockiseq = rc.iseq_c.GetISeqPtr(blockiseqval);
    }

    var num:int = rc.vm_insnhelper_c.caller_setup_args(th, reg_cfp, op_flag, op_argc, blockiseq, blockptr_ref);
    blockptr = blockptr_ref.v;

    var recv:Value;
    var klass:RClass;
    var mn:Node;
    var id:int;
    var flag:uint = RbVm.VM_CALL_SUPER_BIT | RbVm.VM_CALL_FCALL_BIT;

    recv = reg_cfp.self;
    var id_ref:ByRef = new ByRef(id);
    var klass_ref:ByRef = new ByRef(klass);
    rc.vm_insnhelper_c.vm_search_superclass(reg_cfp, rc.vm_insnhelper_c.GET_ISEQ(reg_cfp), recv,
                         reg_cfp.sp.topn(num), id_ref, klass_ref);
    id = id_ref.v;
    klass = klass_ref.v;
    mn = rc.vm_method_c.rb_method_node(klass, id);

    // CALL_METHOD(num, blockptr, flag, id, mn, recv, klass);
    var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, num, blockptr, flag, id, mn, recv, klass);
    if (v == Qundef) {
      RESTORE_REGS();
      // NEXT_INSN();
      return;
    } else {
      val = v;
    }

    reg_sp.push(val);
  }

  public function
  send(op_str:String, op_argc:int, blockiseq_data:*, op_flag:int, ic:Value):void
  {
    var mn:Node;
    var recv:Value;
    var klass:RClass;
    var blockptr:ByRef = new ByRef(null);

    var val:Value;

    var op_id:int = rc.parse_y.rb_intern(op_str);

    var blockiseq:RbISeq;
    if (blockiseq_data is Array) {
      // Guessing at this, but it seems to be needed to pass in parent for a block
      var blockiseqval:Value = rc.iseqval_from_array(blockiseq_data, reg_cfp.iseq.self);
      blockiseq = rc.iseq_c.GetISeqPtr(blockiseqval);
    } else {
      if (blockiseq_data != rc.Qnil) {
        blockiseq = blockiseq_data;
      }
    }

    var num:int = rc.vm_insnhelper_c.caller_setup_args(th, reg_cfp, op_flag, op_argc,
                                                       blockiseq, blockptr);

    var flag:int = op_flag;
    var id:int = op_id;

    recv = ((flag & RbVm.VM_CALL_FCALL_BIT) != 0) ? reg_cfp.self : reg_sp.topn(num);
    klass = rc.CLASS_OF(recv);

    /*
    trace("send "+op_str+" to " + (klass ? klass.name : "?") + " with " + op_argc+ " ops");
    for (var o:int = op_argc-1; o >= 0; o--) {
      trace("       op "+(op_argc-o)+": " + reg_sp.topn(o));
    }
    //*/

    mn = rc.vm_insnhelper_c.vm_method_search(id, klass, ic);
    // TODO: @fix method_missing is not being called here.

    // TODO: @skipped send/funcall optimization
    if ((flag & RbVm.VM_CALL_SEND_BIT) != 0) {
      //vm_send_optimize(cfp, &mn, &flag, &num, &id, klass);
    }

    //CALL_METHOD(num, blockptr, flag, id, mn, recv, klass);
    var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, num, blockptr.v, flag, id, mn, recv, klass);
    if (v == Qundef) {
      RESTORE_REGS();
      // NEXT_INSN();
      // TODO: @skip vm_call_method returns Qundef

      if (false) {
        // Means that stack is setup to run something else already, but we need a function!
        var new_frame:RubyFrame = new RubyFrame(rc, th);
        reg_cfp.iseq.iseq_fn.call(rc, new_frame);
      } else {
        //rc.vm_eval(th, Qnil);
        return;
      }

    } else {
      val = v;
      reg_sp.push(val);
    }

  }

  public function
  JUMP(dst:int):void
  {
    reg_cfp.pc_index += dst;
  }

  public function
  JUMP_LABEL(label:String):void
  {
    var pc:Array = reg_cfp.pc_ary;
    var pc_len:int = pc.length;
    var i:int;
    var started_at:int = reg_cfp.pc_index;
    var found:Boolean = false;
    // search forward, most likely case:
    for (i = started_at; i < pc_len; i++) {
      if (pc[i] == label) {
        found = true;
        break;
      }
    }
    if (found) {
      reg_cfp.pc_index = i;
      return;
    }
    // search backwards
    for (i = started_at-1; i >= 0; i--) {
      if (pc[i] == label) {
        found = true;
        break;
      }
    }
    if (found) {
      reg_cfp.pc_index = i;
      return;
    } else {
      rc.error_c.rb_bug("JUMP_LABEL couldn't find destination");
    }
  }

  public function
  jump(label:String):void
  {
    JUMP_LABEL(label);
  }

  public function
  branchif(label:String):void
  {
    var val:Value = reg_sp.pop()
    if (rc.RTEST(val)) {
      JUMP_LABEL(label);
    }
  }

  public function
  branchunless(label:String):void
  {
    var val:Value = reg_sp.pop()
    if (!rc.RTEST(val)) {
      JUMP_LABEL(label);
    }
  }

  public function
  setlocal(idx:int):void
  {
    reg_cfp.lfp.set_at(-idx, reg_sp.pop());
  }

  public function
  getlocal(idx:int):void
  {
    var val:Value = reg_cfp.lfp.get_at(-idx);
    reg_sp.push(val);
  }

  public function
  duparray(ary:*):void
  {
    var val:Value;
    if (ary is RArray) {
      val = rc.array_c.rb_ary_dup(RArray(ary));
    } else if (ary is Array) {
      var array:Array = ary;
      array = rc.convert_array_to_ruby_value(array);
      var rarray:RArray = rc.array_c.rb_ary_new2(array.length);
      var i:int;
      for (i = 0; i < array.length; i++) {
        rarray.array[i] = array[i];
      }
      rarray.len = array.length;
      val = rarray;
    }
    reg_sp.push(val);
  }

  public function
  setdynamic(idx:int, level:int):void
  {
    var val:Value = reg_cfp.sp.pop();
    var i:int;
    var dfp2:StackPointer = reg_cfp.dfp;
    for (i = 0; i < level; i++) {
      dfp2 = rc.vm_insnhelper_c.GET_PREV_DFP(dfp2);
    }
    dfp2.set_at(-idx, val);
  }

  public function
  getdynamic(idx:int, level:int):void
  {
    var i:int;
    var dfp2:StackPointer = reg_cfp.dfp;
    for (i = 0; i < level; i++) {
      dfp2 = rc.vm_insnhelper_c.GET_PREV_DFP(dfp2);
    }
    var val:Value = dfp2.get_at(-idx);

    reg_cfp.sp.push(val);
  }

  public function
  getinlinecache(ic:Value, dst:String):void
  {
    putnil();
  }

  public function
  onceinlinecache(ic:Value, dst:String):void
  {
    rc.error_c.rb_bug("onceinelinecache unimplemented bytecode");
  }

  public function
  setinlinecache(dst:String):void
  {
  }

  public function
  getinstancevariable(id_str:String):void
  {
    var id:int = rc.parse_y.rb_intern(id_str);
    var val:Value = rc.variable_c.rb_ivar_get(reg_cfp.self, id);
    reg_sp.push(val);
  }

  public function
  setinstancevariable(id_str:String):void
  {
    var id:int = rc.parse_y.rb_intern(id_str);
    var val:Value = reg_sp.pop();
    rc.variable_c.rb_ivar_set(reg_cfp.self, id, val);
  }

  public function
  getclassvariable(id_str:String):void
  {
    var id:int = rc.parse_y.rb_intern(id_str);
    var cref:Node = rc.vm_insnhelper_c.vm_get_cref(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp);
    var val:Value = rc.variable_c.rb_cvar_get(rc.vm_insnhelper_c.vm_get_cvar_base(cref), id);
    reg_sp.push(val);
  }

  public function
  setclassvariable(id_str:String):void
  {
    var id:int = rc.parse_y.rb_intern(id_str);
    var val:Value = reg_sp.pop();
    var cref:Node = rc.vm_insnhelper_c.vm_get_cref(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp);
    rc.variable_c.rb_cvar_set(rc.vm_insnhelper_c.vm_get_cvar_base(cref), id, val);
  }

  // insns.def:218
  public function
  getconstant(id_str:String):void
  {
    var klass:Value = reg_sp.pop();
    var id:int = rc.parse_y.rb_intern(id_str);
    reg_sp.push(rc.vm_insnhelper_c.vm_get_ev_const(th, rc.vm_insnhelper_c.GET_ISEQ(reg_cfp), klass, id, false));
  }

  // insns.def:240
  public function
  setconstant(id_str:String):void
  {
    var cbase:Value = reg_sp.pop();
    var val:Value = reg_sp.pop();
    var id:int = rc.parse_y.rb_intern(id_str);
    rc.vm_insnhelper_c.vm_check_if_namespace(cbase);
    rc.variable_c.rb_const_set(RClass(cbase), id, val);
    rc.vm_c.INC_VM_STATE_VERSION();
  }

  // insns.def:256
  public function
  getglobal(entry:*):void
  {
    var val:Value;
    rc.error_c.rb_bug("getglobal not implemented");
    //val = rc.GET_GLOBAL(entry);
    reg_sp.push(val);
  }

  // insns.def:256
  public function
  setglobal(entry:*):void
  {
    var val:Value = reg_sp.pop();
    rc.error_c.rb_bug("setglobal not implemented");
    //rc.SET_GLOBAL(entry, vl);
  }

  // insns.def:421
  public function
  toregexp(opt:int, cnt:int):void
  {
    var val:Value
    rc.error_c.rb_bug("toregexp not supported");
    reg_sp.push(val);
  }

  // insns.def:479
  public function
  expandarray(num:int, flag:uint):void
  {
    var ary:Value = reg_sp.topn(0);
    rc.error_c.rb_bug("expandarray not implemented");
    //vm_expandarray(reg_cfp, ary, num, flag);
  }

  // insns:def:493
  public function
  concatarray():void
  {
    var ary2st:Value = reg_sp.pop();
    var ary1:Value = reg_sp.pop();
    var ary:Value;

    var ary2:Value = ary2st;
    var tmp1:Value = rc.object_c.rb_check_convert_type(ary1, Value.T_ARRAY, "Array", "to_a");
    var tmp2:Value = rc.object_c.rb_check_convert_type(ary2, Value.T_ARRAY, "Array", "to_a");

    if (rc.NIL_P(tmp1)) {
      tmp1 = rc.array_c.rb_ary_new3(1, ary1);
    }

    if (rc.NIL_P(tmp2)) {
      tmp2 = rc.array_c.rb_ary_new3(1, ary2);
    }

    if (tmp1 == ary1) {
      tmp1 = rc.array_c.rb_ary_dup(RArray(ary1));
    }
    ary = rc.array_c.rb_ary_concat(RArray(tmp1), RArray(tmp2));

    reg_sp.push(ary);
  }

  public function
  rtrace(num:int):void
  {

  }

  // insns.def:873
  public function
  defineclass(id_str:String, class_iseq_data:*, define_type:uint):void
  {
    var klass:RClass;
    var super_class:Value = reg_sp.pop();
    var cbase:RClass = reg_sp.pop();
    var tmpValue:Value;

    var id:int = rc.parse_y.rb_intern(id_str);

    var class_iseq:RbISeq;
    if (class_iseq_data is RbISeq) {
      class_iseq = class_iseq_data;
    } else if (class_iseq_data is Array) {
      var iseqval:Value = rc.iseqval_from_array(class_iseq_data);
      class_iseq = rc.iseq_c.GetISeqPtr(iseqval);
    }

    switch (define_type) {
    case 0:
      // typical class definition
      if (super_class == Qnil) {
        super_class = rc.object_c.rb_cObject;
      }

      rc.vm_insnhelper_c.vm_check_if_namespace(cbase);

      if (rc.variable_c.rb_const_defined_at(cbase, id)) {
        tmpValue = rc.variable_c.rb_const_get_at(cbase, id);
        if (!tmpValue.is_class()) {
          rc.error_c.rb_raise(rc.error_c.rb_eTypeError, rc.parse_y.rc.parse_y.rb_id2name(id)+" is not a class");
        }
        klass = RClass(tmpValue);

        if (super_class != rc.object_c.rb_cObject) {
          var tmp:RClass = rc.object_c.rb_class_real(klass.super_class);
          if (tmp != super_class) {
            rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "superclass mismatch for class " + rc.parse_y.rb_id2name(id));
          }
        }
      } else {
        // Create new class
        klass = rc.class_c.rb_define_class_id(id, RClass(super_class));
        rc.variable_c.rb_set_class_path(klass, cbase, rc.parse_y.rb_id2name(id));
        rc.variable_c.rb_const_set(cbase, id, klass);
        rc.class_c.rb_class_inherited(RClass(super_class), klass);
      }
      break;
    case 1:
      // create singleton class
      klass = rc.class_c.rb_singleton_class(cbase);
      break;
    case 2:
      // create module

      rc.vm_insnhelper_c.vm_check_if_namespace(cbase);

      if (rc.variable_c.rb_const_defined_at(cbase, id)) {
        tmpValue = rc.variable_c.rb_const_get_at(cbase, id);
        if (tmpValue.get_type() != Value.T_MODULE) {
          rc.error_c.rb_raise(rc.error_c.rb_eTypeError, rc.parse_y.rb_id2name(id)+" is not a module");
        }
        klass = RClass(tmpValue);
      } else {
        // new module declaration
        klass = rc.class_c.rb_define_module_id(id);
        rc.variable_c.rb_set_class_path(klass, cbase, rc.parse_y.rb_id2name(id));
        rc.variable_c.rb_const_set(cbase, id, klass);
      }
      break;
    }

    rc.COPY_CREF(class_iseq.cref_stack, rc.vm_c.vm_cref_push(th, klass, Node.NOEX_PUBLIC));

    rc.vm_insnhelper_c.vm_push_frame(th, class_iseq, RbVm.VM_FRAME_MAGIC_CLASS, klass,
                     null/*GET_DFP() | 0x02*/, class_iseq.iseq_fn,
                     class_iseq.iseq, 0, reg_sp.clone(), null,
                     class_iseq.local_size);

    RESTORE_REGS();

    rc.vm_c.INC_VM_STATE_VERSION();
    // NEXT_INSN();
    if (false) {
      var new_frame:RubyFrame = new RubyFrame(rc, th);
      class_iseq.iseq_fn.call(rc, new_frame);
    } else {
      //rc.vm_eval(th, Qnil);
    }

  }

  public function
  newarray(num:int):void
  {
    var val:Value = rc.array_c.rb_ary_new4(num, reg_sp.clone_from_top(num));
    reg_sp.popn(num);
    reg_sp.push(val);
  }

  public function
  newhash(num:int):void
  {
    var i:int;

    var val:Value = rc.hash_c.rb_hash_new();

    for (i = num; i > 0; i-=2) {
      var v:Value = reg_sp.topn(i-2);
      var k:Value = reg_sp.topn(i-1);
      rc.hash_c.rb_hash_aset(val, k, v);
    }
    reg_sp.popn(num);

    reg_sp.push(val);
  }

  // insns.def:1234
  public function
  opt_case_dispatch(hash:Object, else_offset:String):void
  {
    var key:Value = reg_sp.pop();
    rc.error_c.rb_bug("case bytecode not implemented");
  }

  // insns.def:1259
  public function
  opt_checkenv():void
  {
    if (reg_cfp.bp.index != reg_cfp.dfp.index+1 && reg_cfp.bp.stack == reg_cfp.dfp.stack) {
      var new_dfp:StackPointer = reg_cfp.bp.get_at(-1);
      // TODO: copy env and clean stack at creating env?
      new_dfp.set_at(0, reg_cfp.dfp);
      reg_cfp.dfp = new_dfp;
    }
  }

  // insns.def:1790
  public function
  opt_aref():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value = null;
    var done:Boolean = false;

    if (!rc.SPECIAL_CONST_P(recv) && rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_AREF)) {
      if (rc.HEAP_CLASS_OF(recv) == rc.array_c.rb_cArray && rc.FIXNUM_P(obj)) {
        val = rc.array_c.rb_ary_entry(RArray(recv), rc.FIX2LONG(obj));
        done = true;
      }
      else if (rc.HEAP_CLASS_OF(recv) == rc.hash_c.rb_cHash) {
        val = rc.hash_c.rb_hash_aref(recv, obj);
        done = true;
      }
    }
    if (!done) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      //CALL_SIMPLE_METHOD(1, Id_c.idAREF, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idAREF;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);
  }

  // insns.def:1391
  public function
  opt_mult():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;
    var normal_dispatch:Boolean = true;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_DIV)) {
      var a:int, b:int, c:int;

      a = rc.FIX2LONG(recv);
      if (a == 0) {
        val = recv;
      }
      else {
        b = rc.FIX2LONG(obj);
        c = a * b;

        if (true) { //rc.numeric_c.FIXABLE(c) && c / a == b) {
          val = rc.numeric_c.INT2FIX(c);
        }
        else {
          // TODO: @skipped bignum support
          //val = rb_big_mul();
        }
      }
      normal_dispatch = false;
    }
    else if (!rc.SPECIAL_CONST_P(recv) && !rc.SPECIAL_CONST_P(obj)) {
      if (rc.HEAP_CLASS_OF(recv) == rc.numeric_c.rb_cFloat &&
          rc.HEAP_CLASS_OF(obj) == rc.numeric_c.rb_cFloat &&
          rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_MULT)) {
        val = rc.DOUBLE2NUM(RFloat(recv).float_value*RFloat(obj).float_value);
        normal_dispatch = false;
      }
    }
    if (normal_dispatch) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, Id_c.idMINUS, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idMULT;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);

  }


  // insns.def:1444
  public function
  opt_div():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;
    var normal_dispatch:Boolean = true;

    do {
      if (rc.FIXNUM_2_P(recv, obj) &&
          rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_DIV)) {
        var x:int, y:int, div:int;

        x = rc.FIX2LONG(recv);
        y = rc.FIX2LONG(obj);
        {
          // copied from numeric.c#fixdivmod
          var mod:int;
          if (y == 0) {
            // goto INSN_LABEL(normal_dispatch)
            break;
          } else if (y < 0) {
            if (x < 0) {
              div = -x / -y;
            } else {
              div = -(x / -y);
            }
          }
          else {
            if (x < 0) {
              div = -(-x / y);
            } else {
              div = x / y;
            }
          }
          mod = x - div * y;
          if ((mod < 0 && y > 0) || (mod > 0 && y < 0)) {
            mod += y;
            div -= 1;
          }
        }
        val = rc.numeric_c.INT2FIX(div);
        normal_dispatch = false;
        //val = rc.LONG2NUM(div);
      }
      else if (!rc.SPECIAL_CONST_P(recv) && !rc.SPECIAL_CONST_P(obj)) {
        if (rc.HEAP_CLASS_OF(recv) == rc.numeric_c.rb_cFloat &&
            rc.HEAP_CLASS_OF(obj) == rc.numeric_c.rb_cFloat &&
            rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_DIV)) {
          val = rc.DOUBLE2NUM(RFloat(recv).float_value/RFloat(obj).float_value);
          normal_dispatch = false;
        }
      }
    } while (0);
    if (normal_dispatch) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, Id_c.idMINUS, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idDIV;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);

  }

  // insns.def:1357
  public function
  opt_minus():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_MINUS)) {
        var a:int, b:int, c:int;

        a = rc.FIX2LONG(recv);
        b = rc.FIX2LONG(obj);
        c = a - b;

        if (true) { //rc.FIXABLE(c)) {
          val = rc.numeric_c.INT2FIX(c);
        }
        else {
          rc.error_c.rb_bug("big number support not implemented");
          //val = rc.numeric_c.rb_big_minus(rb_int2big(a), rb_int2big(b));
        }
    }
    else {
      // other
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, Id_c.idMINUS, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idMINUS;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);
  }

  // insns.def:1281
  public function
  opt_plus():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_MINUS)) {
        var a:int, b:int, c:int;

        a = rc.FIX2LONG(recv);
        b = rc.FIX2LONG(obj);
        c = a + b;

        if (true) { //rc.FIXABLE(c)) {
          val = rc.numeric_c.INT2FIX(c);
        }
        else {
          rc.error_c.rb_bug("big number support not implemented");
          //val = rc.numeric_c.rb_big_minus(rb_int2big(a), rb_int2big(b));
        }
    }
    else {
      // other
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, Id_c.idPLUS, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idPLUS;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);
  }

  // insns.def:1756
  public function
  opt_ltlt():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;
    var normal_dispatch:Boolean = true;

    if (!rc.SPECIAL_CONST_P(recv)) {
      if (rc.HEAP_CLASS_OF(recv) == rc.string_c.rb_cString &&
          rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_LTLT)) {
        val = rc.string_c.rb_str_concat(RString(recv), obj);
        normal_dispatch = false;
      }
      else if (rc.HEAP_CLASS_OF(recv) == rc.array_c.rb_cArray &&
               rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_LTLT)) {
        val = rc.array_c.rb_ary_push(RArray(recv), obj);
        normal_dispatch = false;
      }
    }
    if (normal_dispatch) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, Id_c.idLTLT, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idLTLT;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }
    reg_sp.push(val);
  }

  // insns.def:1587
  public function
  opt_eq(ic:Value):void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    val = rc.vm_insnhelper_c.opt_eq_func(recv, obj, ic);

    if (val == rc.Qundef) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idEq, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idEq;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1608
  public function
  opt_neq(ic1:Value, ic2:Value):void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    var mn:Node = rc.vm_insnhelper_c.vm_method_search(Id_c.idNeq, rc.CLASS_OF(recv), ic1);
    val = rc.Qundef;

    if (rc.vm_insnhelper_c.check_cfunc(mn, rc.object_c.rb_obj_not_equal)) {
      val = rc.vm_insnhelper_c.opt_eq_func(recv, obj, ic2);

      if (val != rc.Qundef) {
        val = rc.RTEST(val) ? rc.Qfalse : rc.Qtrue;
      }
    }

    if (val == rc.Qundef) {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idEq, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idNeq;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1639
  public function
  opt_lt():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_GT)) {
      var a:int = rc.FIX2LONG(recv);
      var b:int = rc.FIX2LONG(obj);

      if (a < b) {
        val = rc.Qtrue;
      }
      else {
        val = rc.Qfalse;
      }
    }
    else {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idGT, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idLT;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1668
  public function
  opt_le():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_GT)) {
      var a:int = rc.FIX2LONG(recv);
      var b:int = rc.FIX2LONG(obj);

      if (a <= b) {
        val = rc.Qtrue;
      }
      else {
        val = rc.Qfalse;
      }
    }
    else {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idGT, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idLE;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1698
  public function
  opt_gt():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_GT)) {
      var a:int = rc.FIX2LONG(recv);
      var b:int = rc.FIX2LONG(obj);

      if (a > b) {
        val = rc.Qtrue;
      }
      else {
        val = rc.Qfalse;
      }
    }
    else {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idGT, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idGT;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1727
  public function
  opt_ge():void
  {
    var obj:Value = reg_sp.pop();
    var recv:Value = reg_sp.pop();
    var val:Value;

    if (rc.FIXNUM_2_P(recv, obj) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_GT)) {
      var a:int = rc.FIX2LONG(recv);
      var b:int = rc.FIX2LONG(obj);

      if (a >= b) {
        val = rc.Qtrue;
      }
      else {
        val = rc.Qfalse;
      }
    }
    else {
      reg_sp.push(recv);
      reg_sp.push(obj);
      // CALL_SIMPLE_METHOD(1, idGT, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idGE;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 1, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }


  // insns.def:1851
  public function
  opt_length():void
  {
    var recv:Value = reg_sp.pop();
    var val:Value;

    var normal_dispatch:Boolean = true;
    if (!rc.SPECIAL_CONST_P(recv) &&
        rc.BASIC_OP_UNREDEFINED_P(RbVm.BOP_LENGTH)) {
      if (rc.HEAP_CLASS_OF(recv) == rc.string_c.rb_cString) {
        val = rc.numeric_c.INT2FIX(RString(recv).string.length);
        normal_dispatch = false;
      }
      else if (rc.HEAP_CLASS_OF(recv) == rc.array_c.rb_cArray) {
        val = rc.numeric_c.INT2FIX(RArray(recv).len);
        normal_dispatch = false;
      }
      else if (rc.HEAP_CLASS_OF(recv) == rc.hash_c.rb_cHash) {
        //val = rc.numeric_c.INT2FIX((RHash(recv).ntbl);
      }
    }
    if (normal_dispatch) {
      reg_sp.push(recv);
      // CALL_SIMPLE_METHOD(0, idLength, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = rc.id_c.idLength;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 0, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:1934
  public function
  opt_not(ic:Value):void
  {
    var recv:Value = reg_sp.pop();
    var val:Value;

    var mn:Node = rc.vm_insnhelper_c.vm_method_search(Id_c.idNot, rc.CLASS_OF(recv), ic);

    if (rc.vm_insnhelper_c.check_cfunc(mn, rc.object_c.rb_obj_not)) {
      val = rc.RTEST(recv) ? rc.Qfalse : rc.Qtrue;
    }
    else {
      reg_sp.push(recv);
      // CALL_SIMPLE_METHOD(0, idNot, recv);
      var klass:RClass = rc.CLASS_OF(recv);
      var id:int = Id_c.idNot;
      //CALL_METHOD(num, 0, 0, id, rb_method_node(klass, id), recv, rc.CLASS_OF(recv));
      var v:Value = rc.vm_insnhelper_c.vm_call_method(th, reg_cfp, 0, null, 0,
                                                      id,
                                                      rc.vm_method_c.rb_method_node(klass, id),
                                                      recv, rc.CLASS_OF(recv));
      if (v == rc.Qundef) {
        RESTORE_REGS();
        return;
      } else {
        val = v;
      }
    }

    reg_sp.push(val);
  }

  // insns.def:406
  public function
  tostring():void
  {
    var val:Value = reg_sp.pop();
    val = rc.string_c.rb_obj_as_string(val);
    reg_sp.push(val);
  }

  // insns.def:385
  public function
  concatstrings(num:int):void
  {
    var val:RString;
    var i:int;
    val = rc.string_c.rb_str_new("");
    for ( i = num - 1; i >= 0; i--) {
      var v:RString = reg_sp.topn(i);
      rc.string_c.rb_str_append(val, v);
    }
    reg_sp.popn(num);

    reg_sp.push(val);
  }

}
}

