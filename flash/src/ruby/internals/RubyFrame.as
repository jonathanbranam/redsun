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
    reg_sp.push(rc.rb_str_new(str));
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
      reg_sp.push(rc.rb_str_new(val));
    } else if (val is Number) {
      reg_sp.push(rc.INT2FIX(val));
    }
  }

  public function
  putspecialobject(value_type:int):void
  {
    switch (value_type) {
      case RbVm.VM_SPECIAL_OBJECT_VMCORE:
        reg_sp.push(rc.rb_mRubyVMFrozenCore);
        break;
      case RbVm.VM_SPECIAL_OBJECT_CBASE:
        reg_sp.push(rc.vm_get_cbase(reg_cfp.iseq, reg_cfp.lfp, reg_cfp.dfp));
        break;
      default:
        rc.rb_bug("putspecialobject insn: unknown value_type: " + value_type);
    }
  }


  public function
  leave():void
  {
    var val:Value = reg_sp.pop();
    //trace("leave retval: " + val);
    if (!reg_sp.equals(reg_cfp.bp)) {
      rc.rb_bug("Stack consistency error (sp: "+reg_sp+", bp: " +reg_cfp.bp +")");
    }
    // RUBY_VM_CHECK_INTS();
    rc.vm_pop_frame(th);
    RESTORE_REGS();
    reg_sp.push(val);
  }

  public function
  send(op_str:String, op_argc:int, blockiseq:Value, op_flag:int, ic:Value):void
  {
    var mn:Node;
    var recv:Value;
    var klass:RClass;
    var blockptr:ByRef = new ByRef();

    var val:Value;

    var op_id:int = rc.rb_intern(op_str)

    var num:int = rc.caller_setup_args(th, reg_cfp, op_flag, op_argc, blockiseq, blockptr);

    var flag:int = op_flag;
    var id:int = op_id;

    recv = ((flag & RbVm.VM_CALL_FCALL_BIT) != 0) ? reg_cfp.self : reg_sp.topn(num);
    klass = rc.CLASS_OF(recv);

    /*
    trace("send "+op_str+" to " + klass.name + " with " + op_argc+ " ops");
    for (var o:int = op_argc-1; o >= 0; o--) {
      trace("       op "+(op_argc-o)+": " + reg_sp.topn(o));
    }
    */

    mn = rc.vm_method_search(id, klass, ic);
    // TODO: @fix method_missing is not being called here.

    // TODO: @skipped send/funcall optimization
    if ((flag & RbVm.VM_CALL_SEND_BIT) != 0) {
      //vm_send_optimize(cfp, &mn, &flag, &num, &id, klass);
    }

    //CALL_METHOD(num, blockptr, flag, id, mn, recv, klass);
    var v:Value = rc.vm_call_method(th, reg_cfp, num, blockptr.v, flag, id, mn, recv, klass);
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

  public function branchunless():Boolean {
    return rc.RTEST(reg_sp.pop());
  }

  public function setlocal(idx:int):void {
    reg_cfp.lfp.set_at(-idx, reg_sp.pop());
  }

  public function getlocal(idx:int):void {
    var val:Value = reg_cfp.lfp.get_at(-idx);
    reg_sp.push(val);
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
  getconstant(id_str:String):void
  {
    var klass:Value = reg_sp.pop();
    var id:int = rc.rb_intern(id_str);
    reg_sp.push(rc.vm_get_ev_const(th, rc.GET_ISEQ(reg_cfp), klass, id, false));
  }

  public function
  rtrace(num:int):void
  {

  }

  // insns.def:873
  public function
  defineclass(id_str:String, class_iseq:RbISeq, define_type:uint):void
  {
    var klass:RClass;
    var super_class:Value = reg_sp.pop();
    var cbase:RClass = reg_sp.pop();
    var tmpValue:Value;

    var id:int = rc.rb_intern(id_str);

    switch (define_type) {
    case 0:
      // typical class definition
      if (super_class == Qnil) {
        super_class = rc.rb_cObject;
      }

      // vm_check_if_namespace(cbase);

      if (rc.rb_const_defined_at(cbase, id)) {
        tmpValue = rc.rb_const_get_at(cbase, id);
        if (!tmpValue.is_class()) {
          rc.rb_raise(rc.rb_eTypeError, rc.rb_id2name(id)+" is not a class");
        }
        klass = RClass(tmpValue);

        if (super_class != rc.rb_cObject) {
          var tmp:RClass = rc.rb_class_real(klass.super_class);
          if (tmp != super_class) {
            rc.rb_raise(rc.rb_eTypeError, "superclass mismatch for class " + rc.rb_id2name(id));
          }
        }
      } else {
        // Create new class
        klass = rc.rb_define_class_id(id, RClass(super_class));
        rc.rb_set_class_path(klass, cbase, rc.rb_id2name(id));
        rc.rb_const_set(cbase, id, klass);
        rc.rb_class_inherited(RClass(super_class), klass);
      }
      break;
    case 1:
      // create singleton class
      klass = rc.rb_singleton_class(cbase);
      break;
    case 2:
      // create module

      // vm_check_if_namespace(cbase);

      if (rc.rb_const_defined_at(cbase, id)) {
        tmpValue = rc.rb_const_get_at(cbase, id);
        if (tmpValue.get_type() != Value.T_MODULE) {
          rc.rb_raise(rc.rb_eTypeError, rc.rb_id2name(id)+" is not a module");
        }
        klass = RClass(tmpValue);
      } else {
        // new module declaration
        klass = rc.rb_define_module_id(id);
        rc.rb_set_class_path(klass, cbase, rc.rb_id2name(id));
        rc.rb_const_set(cbase, id, klass);
      }
      break;
    }

    rc.COPY_CREF(class_iseq.cref_stack, rc.vm_cref_push(th, klass, Node.NOEX_PUBLIC));

    rc.vm_push_frame(th, class_iseq, RbVm.VM_FRAME_MAGIC_CLASS, klass,
                     null/*GET_DFP() | 0x02*/, class_iseq.iseq_fn,
                     class_iseq.iseq, 0, reg_sp.clone(), null,
                     class_iseq.local_size);

    RESTORE_REGS();

    rc.INC_VM_STATE_VERSION();
    // NEXT_INSN();
    if (false) {
      var new_frame:RubyFrame = new RubyFrame(rc, th);
      class_iseq.iseq_fn.call(rc, new_frame);
    } else {
      //rc.vm_eval(th, Qnil);
    }

  }



}
}

