package ruby.internals
{
public class RubyFrame
{
  public var rc:RubyCore;
  public var th:RbThread;
  public var cfp:RbControlFrame;

  public var Qnil:Value;
  public var Qfalse:Value;
  public var Qtrue:Value;
  public var Qundef:Value;

  public function RubyFrame(rc:RubyCore, th:RbThread, cfp:RbControlFrame)
  {
    this.rc = rc;
    this.th = th;
    this.cfp = cfp;

    this.Qnil = rc.Qnil;
    this.Qfalse = rc.Qfalse;
    this.Qtrue = rc.Qtrue;
    this.Qundef = rc.Qundef;
  }

  public function pop():void {
    cfp.sp.pop();
  }

  public function putnil():void {
    cfp.sp.push(Qnil);
  }

  public function putstring(str:String):void {
    cfp.sp.push(rc.rb_str_new(str));
  }

  public function putiseq(iseq:RbISeq):void {
    cfp.sp.push(iseq.self);
  }

  public function putobject(str:String):void {
    cfp.sp.push(rc.rb_str_new(str));
  }

  public function putspecialobject(value_type:int):void {
    switch (value_type) {
      case RbVm.VM_SPECIAL_OBJECT_VMCORE:
        cfp.sp.push(rc.rb_mRubyVMFrozenCore);
        break;
      case RbVm.VM_SPECIAL_OBJECT_CBASE:
        cfp.sp.push(rc.vm_get_cbase(cfp.iseq, cfp.lfp, cfp.dfp));
        break;
      default:
        rc.rb_bug("putspecialobject insn: unknown value_type: " + value_type);
    }
  }


  public function leave():void {
    if (cfp.sp != cfp.bp) {
      rc.rb_bug("Stack consistency error (sp: "+cfp.sp+", bp: " +cfp.bp +")");
    }
    // RUBY_VM_CHECK_INTS();
    rc.vm_pop_frame(th);
    // RESTORE_REGS();
  }

  public function send(op_str:String, op_argc:int, blockiseq:Value, op_flag:int, ic:Value):void {
    var mn:Node;
    var recv:Value;
    var klass:RClass;
    var blockptr:ByRef = new ByRef();

    var val:Value;

    var op_id:int = rc.rb_intern(op_str)

    var num:int = rc.caller_setup_args(th, cfp, op_flag, op_argc, blockiseq, blockptr);

    var flag:int = op_flag;
    var id:int = op_id;

    recv = (flag & RbVm.VM_CALL_FCALL_BIT) ? cfp.self : rc.TOPN(cfp.sp, num);
    klass = rc.CLASS_OF(recv);
    mn = rc.vm_method_search(id, klass, ic);

    // send/funcall optimization

    //CALL_METHOD(num, blockptr, flag, id, mn, recv, klass);
    var v:Value = rc.vm_call_method(th, cfp, num, blockptr.v, flag, id, mn, recv, klass);
    if (v == Qundef) {
      // This is already handled, perhaps, so just continue?
      // RESTORE_REGS();
      // NEXT_INSN();
    } else {
      val = v;
      cfp.sp.push(val);
    }

  }

  public function setlocal(idx:int):void {
    cfp.lfp[idx] = cfp.sp.pop();
  }

  public function getlocal(idx:int):void {
    cfp.sp.push(cfp.lfp[idx]);
  }

  public function
  getinlinecache(ic:int, dst:String):void
  {
    putnil();
  }

  public function
  getconstant(id_str:String):void
  {
    //cfp.sp.push(rc.vm_get_ev_const(th, GET_ISEQ(), klass, id, 0);
  }

  // insns.def:873
  public function defineclass(id_str:String, class_iseq:RbISeq, define_type:uint):void
  {
    var klass:RClass;
    var super_class:Value = cfp.sp.pop();
    var cbase:RClass = cfp.sp.pop();
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

    rc.vm_push_frame(th, class_iseq, RbVm.VM_FRAME_MAGIC_CLASS, klass, null/*GET_DFP() | 0x02*/,
                     class_iseq.iseq_fn, cfp.sp, null, class_iseq.local_size);

    // RESTORE_REGS();

    // INC_VM_STATE_VERSION();
    // NEXT_INSN();
    var new_frame:RubyFrame = new RubyFrame(rc, th, th.cfp);
    class_iseq.iseq_fn.call(rc, new_frame);

  }



}
}
