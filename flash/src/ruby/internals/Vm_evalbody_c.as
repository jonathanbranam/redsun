  // vm_evalbody.c:30
  public function
  vm_eval(th:RbThread, initial:Value):Value
  {
    var ret:Value;

    var frame:RubyFrame = new RubyFrame(this, th, th.cfp);

    ret = th.cfp.pc.call(this, frame);

    if (th.cfp.VM_FRAME_TYPE() != RbVm.VM_FRAME_MAGIC_FINISH) {
      rb_bug("cfp consistency error");
    }

    ret = th.cfp.sp.pop();
    //th.cfp++ // pop cf

    return ret;
  }

