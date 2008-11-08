package ruby.internals
{
public class Proc_c
{
  public var rc:RubyCore;

  import ruby.internals.RData;
  import ruby.internals.Value;

  public var rb_cUnboundMethod:RClass;
  public var rb_cMethod:RClass;
  public var rb_cBinding:RClass;
  public var rb_cProc:RClass;

  // proc.c:73
  public function
  rb_obj_is_proc(proc:Value):Boolean
  {
    if (rc.TYPE(proc) == Value.T_DATA &&
        RData(proc).dfree == proc_free) {
        return true;
    }
    else {
      return false;
    }
  }

  // proc.c:35
  public function
  proc_free(ptr:*):void
  {
    rc.error_c.rb_bug("proc_free");
  }

  // proc.c:63
  public function
  rb_proc_alloc(klass:RClass):Value
  {
    var obj:Value;
    var proc:RbProc;
    obj = rc.Data_Wrap_Struct(klass, new RbProc(), null, proc_free);
    return obj;
  }

  // proc.c:342
  public function
  proc_new(klass:RClass, is_lambda:Boolean):Value
  {
    var procval:Value = rc.Qnil;
    var th:RbThread = rc.GET_THREAD();
    var cfp:RbControlFrame = th.cfp;
    var block:RbBlock;

    if (cfp.lfp.get_at(0) is RbBlock) {
      block = cfp.lfp.get_at(0);
      cfp = rc.vm_c.RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);
    }
    else {
      cfp = rc.vm_c.RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);

      if (cfp.lfp.get_at(0) is RbBlock) {
        block = cfp.lfp.get_at(0);
        if (block.proc) {
          return block.proc;
        }

        // TODO: check more (cfp limit, called via cfunc, etc)
        while (!cfp.dfp.equals(block.dfp)) {
          cfp = rc.vm_c.RUBY_VM_PREVIOUS_CONTROL_FRAME(th, cfp);
        }

        if (is_lambda) {
          rc.error_c.rb_warn("tried to create Proc object without a block");
        }
      }
      else {
        rc.error_c.rb_raise(rc.error_c.rb_eArgError,
                            "tried to create Proc object without a block");
      }
    }

    procval = block.proc;
    if (procval && RBasic(procval).klass == klass) {
      return procval;
    }

    procval = rc.vm_c.vm_make_proc(th, cfp, block, klass);

    if (is_lambda) {
      var proc2:RbProc;
      proc2 = rc.vm_c.GetProcPtr(procval);
      proc2.is_lambda = true;
    }
    return procval;
  }

  // proc.c:415
  public function
  rb_proc_s_new(argc:int, argv:StackPointer, klass:RClass):Value
  {
    var block:Value = proc_new(klass, false);

    rc.eval_c.rb_obj_call_init(block, argc, argv);
    return block;
  }

  // proc.c:431
  public function
  rb_block_proc(...args):Value
  {
    return proc_new(rb_cProc, false);
  }

  // proc.c:437
  public function
  rb_block_lambda(...args):Value
  {
    return proc_new(rb_cProc, true);
  }

  // proc.c:443
  public function
  rb_f_lambda():Value
  {
    rc.error_c.rb_warn("rb_f_lambda() is deprecated; use rb_block_proc() instead");
    return rb_block_lambda();
  }

  // proc.c:498
  public function
  proc_call(argc:int, argv:StackPointer, procval:Value):Value
  {
    var proc:RbProc;
    var blockptr:RbBlock;
    proc = rc.vm_c.GetProcPtr(procval);

    if (proc.block.block_iseq.BUILTIN_TYPE() == Value.T_NODE ||
        proc.block.block_iseq.arg_block != 1) {

      if (rc.eval_c.rb_block_given_p()) {
        var proc2:RbProc;
        var procval2:Value;
        procval = rb_block_proc();
        proc = rc.vm_c.GetProcPtr(procval);
        blockptr = proc.block;
      }
    }

    return rc.vm_c.vm_invoke_proc(rc.GET_THREAD(), proc, proc.block.self,
                                  argc, argv, blockptr);

  }

  // proc.c:1740
  public function
  Init_Proc():void
  {
    // Proc
    rb_cProc = rc.class_c.rb_define_class("Proc", rc.object_c.rb_cObject);

    rc.eval_c.rb_eLocalJumpError = rc.class_c.rb_define_class("LocalJumpError", rc.error_c.rb_eStandardError);

    rc.eval_c.rb_eSysStackError = rc.class_c.rb_define_class("SystemStackError", rc.error_c.rb_eException);

    rb_cMethod = rc.class_c.rb_define_class("Method", rc.object_c.rb_cObject);

    rc.class_c.rb_define_global_function("proc", rb_block_proc, 0);
    //rc.class_c.rb_define_global_function("lambda", proc_lambda, 0);

    rb_cUnboundMethod = rc.class_c.rb_define_class("UnboundMethod", rc.object_c.rb_cObject);

  }

  // proc.c:1857
  public function
  Init_Binding():void
  {
    rb_cBinding = rc.class_c.rb_define_class("Binding", rc.object_c.rb_cObject);
    rc.class_c.rb_define_method(rb_cProc, "call", proc_call, -1);
    rc.class_c.rb_define_method(rb_cProc, "[]", proc_call, -1);
  }

}
}
