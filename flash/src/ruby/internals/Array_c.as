package ruby.internals
{
public class Array_c
{
  public var rc:RubyCore;

  public var rb_cArray:RClass;

  public static const ARY_DEFAULT_SIZE:int = 16;
  public static const ARY_MAX_SIZE:int = int(int.MAX_VALUE / 4);

  // array.c:26
  public function
  rb_mem_clear(mem:StackPointer, size:int):void
  {
    var i:int;
    for (i = 0; i < size; i++) {
      mem.set_at(i, rc.Qnil);
    }
  }

  // array.c:41
  public function
  ARY_SHARED_P(a:Value):Boolean
  {
    return (a.flags & Value.ELTS_SHARED) != 0;
  }

  // array.c:54
  public function
  rb_ary_modify_check(ary:Value):void
  {
    // TODO: @skipped
    // TAINT and TRUST checks
  }

  // array.c:62
  public function
  rb_ary_modify(ary:Value):void
  {
    var ptr:Value;

    rb_ary_modify_check(ary);
    if (ARY_SHARED_P(ary)) {
      rc.error_c.rb_bug("Copy on modify not implemented.");
      // remove shared setting
      // copy array
    }
  }

  // array.c:98
  public function
  ary_alloc(klass:RClass):RArray
  {
    var ary:RArray = new RArray(klass);
    return ary;
  }

  // array.c:111
  public function
  ary_new(klass:RClass, len:int):RArray
  {
    var ary:RArray;

    if (len < 0) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "negative array size (or size too big)");
    }
    if (len > ARY_MAX_SIZE) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "array size too big");
    }
    ary = ary_alloc(klass);
    if (len == 0) len++;
    ary.array = new Array(len);

    return ary;
  }

  // array.c:130
  public function
  rb_ary_new2(len:int):RArray
  {
    return ary_new(rb_cArray, len);
  }

  // array.c:137
  public function
  rb_ary_new():RArray
  {
    return rb_ary_new2(ARY_DEFAULT_SIZE);
  }

  // array.c:145
  public function
  rb_ary_new3(n:int, ...args):RArray
  {
    var ary:RArray;
    var i:int;

    ary = rb_ary_new2(n);

    for (i = 0; i < n; i++) {
      ary.array[i] = args[i];
    }

    ary.len = n;
    return ary;
  }

  // array.c:164
  public function
  rb_ary_new4(n:int, elts:StackPointer):RArray
  {
    var ary:RArray;

    ary = rb_ary_new2(n);
    if (n > 0 && elts) {
      var i:int;
      for (i = 0; i < n; i++) {
        ary.array[i] = elts.get_at(i);
      }
      ary.len = n;
    }

    return ary;
  }

  // array.c:218
  public function
  to_ary(ary:Value):Value
  {
    return rc.object_c.rb_convert_type(ary, Value.T_ARRAY, "Array", "to_ary");
  }

  // array.c:372
  public function
  rb_ary_store(ary:RArray, idx:int, val:Value):void
  {
    if (idx < 0) {
      idx += ary.len;
      if (idx < 0) {
        rc.error_c.rb_raise(rc.error_c.rb_eIndexError, "index " + (idx - ary.len) +
                            " out of array");
      }
    }
    else if (idx > ARY_MAX_SIZE) {
      rc.error_c.rb_raise(rc.error_c.rb_eIndexError, "index "+idx+" too big");
    }

    rb_ary_modify(ary);
    if (idx > ary.array.length) {
    }
    if (idx >= ary.len) {
      ary.len = idx + 1;
    }
    ary.array[idx] = val;
  }

  // array.c:461
  public function
  rb_ary_push(ary:RArray, item:Value):Value
  {
    rb_ary_store(ary, RArray(ary).len, item);
    return ary;
  }

  // array.c:646
  public function
  rb_ary_elt(ary:RArray, offset:int):Value
  {
    if (ary.len == 0) return rc.Qnil;
    if (offset < 0 || ary.len <= offset) {
      return rc.Qnil;
    }
    return ary.array[offset];
  }

  // array.c:656
  public function
  rb_ary_entry(ary:RArray, offset:int):Value
  {
    if (offset < 0) {
      offset += ary.len;
    }
    return rb_ary_elt(ary, offset);
  }

  // array.c:958
  public function
  rb_ary_to_ary(obj:Value):Value
  {
    if (rc.TYPE(obj) == Value.T_ARRAY) {
      return obj;
    }
    if (rc.vm_method_c.rb_respond_to(obj, rc.parse_y.rb_intern("to_ary"))) {
      return to_ary(obj);
    }
    return rb_ary_new3(1, obj);
  }

  // array.c:970
  public function
  rb_ary_splice(ary:RArray, beg:int, len:int, rpl:Value):void
  {
    var rlen:int;
    var i:int;

    if (len < 0) {
      rc.error_c.rb_raise(rc.error_c.rb_eIndexError,
                          "negative length ("+len+")");
    }
    if (beg < 0) {
      beg += ary.len;
      if (beg < 0) {
        beg -= ary.len;
        rc.error_c.rb_raise(rc.error_c.rb_eIndexError,
                            "index "+ beg+ " out of array");
      }
    }
    if (ary.len < len  || ary.len < (beg + len)) {
      len = ary.len - beg;
    }

    if (rpl == rc.Qundef) {
      rlen = 0;
    }
    else {
      rpl = rb_ary_to_ary(rpl);
      rlen = RArray(rpl).len;
    }
    rb_ary_modify(ary);
    if (beg >= ary.len) {
      if (beg > ARY_MAX_SIZE - rlen) {
        rc.error_c.rb_raise(rc.error_c.rb_eIndexError, "index " + beg+" too big");
      }
      len = beg + rlen;
      if (len >= ary.array.length) {
        ary.array.length = len;
      }
      rb_mem_clear(new StackPointer(ary.array, len), beg - ary.len);
      if (rlen > 0) {
        var rary:RArray = RArray(ary);
        for (i = 0; i < rlen; i++) {
          ary.array[beg+i] = rary.array[i];
        }
        ary.len = len;
      }
    }
    else {
      var alen:int;

      if (beg + len > ary.len) {
        len = ary.len - beg;
      }

      alen = ary.len + rlen - len;
      if (alen > ary.array.length) {
        ary.array.length = alen;
      }

      if (len != rlen) {
        var end:int = ary.len - (beg + len);
        for (i = 0; i < end; i++) {
          ary.array[beg+rlen+i] = ary.array[beg+len+i];
        }
      }
      if (rlen > 0) {
        for (i = 0; i < rlen; i++) {
          ary.array[beg+i] = RArray(rpl).array[i];
        }
      }
    }
  }

  // array.c:1135
  public function
  rb_ary_each(aryv:Value):Value
  {
    var i:int;
    var ary:RArray = RArray(aryv);

    //RETURN_ENUMERATOR(ary, 0, null);
    if (!rc.eval_c.rb_block_given_p()) {
      rc.error_c.rb_bug("rb_ary_each no missing block support");
      //return rb_enumeratorize(obj, rc.ID2SYM(rb_frame_this_func()), argc, argv);
    }
    for (i = 0; i < ary.len; i++) {
      rc.vm_eval_c.rb_yield(ary.array[i]);
    }
    return ary;
  }

  // array.c:1238
  public function
  rb_ary_dup(ary:RArray):RArray
  {
    var dup:RArray = rb_ary_new2(ary.len);
    // DUPSETUP
    var i:int;
    for (i = 0; i < ary.len; i++) {
      dup.array[i] = ary.array[i];
    }
    dup.len = ary.len;
    return dup;
  }

  // array.c:2263
  public function
  rb_ary_concat(x:RArray, yv:Value):RArray
  {
    var y:RArray = RArray(to_ary(yv));
    if (y.len > 0) {
      rb_ary_splice(x, x.len, 0, y);
    }
    return x;
  }

  // array.c:3547
  public function
  Init_Array():void
  {
    rb_cArray = rc.class_c.rb_define_class("Array", rc.object_c.rb_cObject);
    rc.class_c.rb_include_module(rb_cArray, rc.enum_c.rb_mEnumerable);

    rc.class_c.rb_define_method(rb_cArray, "each", rb_ary_each, 0);
  }

}
}
