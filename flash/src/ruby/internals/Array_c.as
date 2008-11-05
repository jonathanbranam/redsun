package ruby.internals
{
public class Array_c
{
  public var rc:RubyCore;

  public var rb_cArray:RClass;

  public static const ARY_DEFAULT_SIZE:int = 16;
  public static const ARY_MAX_SIZE:int = int(int.MAX_VALUE / 4);

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
