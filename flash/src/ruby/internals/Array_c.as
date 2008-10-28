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
  ary_new(klass:RClass, len:int, contents:Array=null):RArray
  {
    var ary:RArray;

    if (contents != null) {
      len = contents.length;
    }

    if (len < 0) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "negative array size (or size too big)");
    }
    if (len > ARY_MAX_SIZE) {
      rc.error_c.rb_raise(rc.error_c.rb_eArgError, "array size too big");
    }
    ary = ary_alloc(klass);
    if (len == 0) len++;
    if (contents != null) {
      ary.array = contents;
    } else {
      ary.array = new Array(len);
    }

    return ary;
  }

  // array.c:130
  public function
  rb_ary_new2(len:int, contents:Array=null):RArray
  {
    return ary_new(rb_cArray, len, contents);
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

    if (n > 0 && elts) {
      ary = rb_ary_new2(n, elts.copy(n));
    } else {
      ary = rb_ary_new2(n);

    }

    return ary;
  }

  // array.c:372
  public function
  rb_ary_store(ary:RArray, idx:int, val:Value):void
  {
    if (idx < 0) {
      idx += ary.array.length;
      if (idx < 0) {
        rc.error_c.rb_raise(rc.error_c.rb_eIndexError, "index " + (idx - ary.array.length) +
                            " out of array");
      }
    }
    else if (idx > ARY_MAX_SIZE) {
      rc.error_c.rb_raise(rc.error_c.rb_eIndexError, "index "+idx+" too big");
    }

    rb_ary_modify(ary);
    if (idx > ary.array.length) {
    }
    ary.array[idx] = val;
  }

  // array.c:461
  public function
  rb_ary_push(ary:RArray, item:Value):Value
  {
    rb_ary_store(ary, RArray(ary).array.length, item);
    return ary;
  }

  // array.c:646
  public function
  rb_ary_elt(ary:RArray, offset:int):Value
  {
    if (ary.array.length == 0) return rc.Qnil;
    if (offset < 0 || ary.array.length <= offset) {
      return rc.Qnil;
    }
    return ary.array[offset];
  }

  // array.c:656
  public function
  rb_ary_entry(ary:RArray, offset:int):Value
  {
    if (offset < 0) {
      offset += ary.array.length;
    }
    return rb_ary_elt(ary, offset);
  }

  // array.c:1238
  public function
  rb_ary_dup(ary:RArray):RArray
  {
    var dup:RArray = rb_ary_new2(ary.array.length, ary.array.concat());
    return dup;
  }

  // array.c:3547
  public function
  Init_Array():void
  {
    rb_cArray = rc.class_c.rb_define_class("Array", rc.object_c.rb_cObject);
    rc.class_c.rb_include_module(rb_cArray, rc.enum_c.rb_mEnumerable);
  }

}
}
