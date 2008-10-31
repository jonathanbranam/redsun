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

  public function
  putobject(val:*):void
  {
    if (val is String) {
      reg_sp.push(rc.string_c.rb_str_new(val));
    } else if (val is Number) {
      reg_sp.push(rc.numeric_c.INT2FIX(val));
    } else if (val === rc.Qfalse) {
      reg_sp.push(val);
    } else if (val === rc.Qtrue) {
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

  public function
  send(op_str:String, op_argc:int, blockiseq_data:*, op_flag:int, ic:Value):void
  {
    var mn:Node;
    var recv:Value;
    var klass:RClass;
    var blockptr:ByRef = new ByRef();

    var val:Value;

    var op_id:int = rc.parse_y.rb_intern(op_str)

    var blockiseq:RbISeq;
    if (blockiseq_data is Array) {
      // Guessing at this, but it seems to be needed to pass in parent for a block
      var blockiseqval:Value = rc.iseqval_from_array(blockiseq_data, reg_cfp.iseq.self);
      blockiseq = rc.iseq_c.GetISeqPtr(blockiseqval);
    }

    var num:int = rc.vm_insnhelper_c.caller_setup_args(th, reg_cfp, op_flag, op_argc, blockiseq, blockptr);

    var flag:int = op_flag;
    var id:int = op_id;

    recv = ((flag & RbVm.VM_CALL_FCALL_BIT) != 0) ? reg_cfp.self : reg_sp.topn(num);
    klass = rc.CLASS_OF(recv);

    /*
    trace("send "+op_str+" to " + (klass ? klass.name : "?") + " with " + op_argc+ " ops");
    for (var o:int = op_argc-1; o >= 0; o--) {
      trace("       op "+(op_argc-o)+": " + reg_sp.topn(o));
    }
    */


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

  public function branchif():Boolean {
    return !rc.RTEST(reg_sp.pop());
  }

  public function
  branchunless():Boolean
  {
    return rc.RTEST(reg_sp.pop());
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
      val = rc.array_c.rb_ary_new2(array.length, array);
    }
    reg_sp.push(val);
  }

  public function
  dup():void
  {
    var val:* = reg_sp.pop();
    reg_sp.push(val);
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
  getconstant(id_str:String):void
  {
    var klass:Value = reg_sp.pop();
    var id:int = rc.parse_y.rb_intern(id_str);
    reg_sp.push(rc.vm_insnhelper_c.vm_get_ev_const(th, rc.vm_insnhelper_c.GET_ISEQ(reg_cfp), klass, id, false));
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

      // vm_check_if_namespace(cbase);

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

      // vm_check_if_namespace(cbase);

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
      /*
      else if (rc.HEAP_CLASS_OF(recv) == rc.hash_c.rb_cHash) {
        val - rb_hash_aref(recv, obj);
      }*/
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

  // insns.def:712
  public function
  setn(n:int):void
  {
    var val:Value = reg_sp.pop();
    reg_sp.set_topn(n-1, val);
    reg_sp.push(val);
  }

}
}

