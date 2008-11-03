package ruby.internals
{
  import flash.utils.Dictionary;

public class Hash_c
{
  public var rc:RubyCore;

  protected static var HASH_DELETED:uint = Value.FL_USER1;
  protected static var HASH_PROC_DEFAULT:uint = Value.FL_USER2;

  protected var id_hash:int, id_yield:int, id_default:int;

  public var rb_cHash:RClass;

  // hash.c:216
  public function
  hash_alloc(klass:RClass):Value
  {
    var hash:RHash = new RHash(klass);
    hash.ifnone = rc.Qnil;

    return hash;
  }

  // hash.c:227
  public function
  rb_hash_new():Value
  {
    return hash_alloc(rb_cHash);
  }

  // hash.c:248
  public function
  rb_hash_modify_check(hash:Value):void
  {
    if (rc.OBJ_FROZEN(hash)) rc.error_c.rb_error_frozen("hash");
    if (!rc.OBJ_UNTRUSTED(hash) && rc.rb_safe_level() >= 4)
      rc.error_c.rb_raise(rc.error_c.rb_eSecurityError, "Insecure: can't modify hash");
  }

  // hash.c:256
  public function
  rb_hash_tbl(hashv:Value):Dictionary
  {
    var hash:RHash = RHash(hashv);
    if (!hash.ntbl) {
      hash.ntbl = new Dictionary();
    }
    return hash.ntbl;
  }

  // hash.c:265
  public function
  rb_hash_modify(hash:Value):void
  {
    rb_hash_modify_check(hash);
    rb_hash_tbl(hash);
  }

  protected function
  key_from_value(keyv:Value):*
  {
    var key:*;
    if (keyv is RString) {
      key = RString(keyv).string;
    } else if (keyv is RInt) {
      key = RInt(keyv).value;
    } else {
      key = keyv;
    }
    return key;
  }

  // hash.c:467
  public function
  rb_hash_aref(hashv:Value, keyv:Value):Value
  {
    var hash:RHash = RHash(hashv);
    var val:Value;
    var key:* = key_from_value(keyv);

    if (!hash.ntbl || hash.ntbl[key] == undefined) {
      return rc.vm_eval_c.rb_funcall(hash, id_default, 1, key);
    }
    return hash.ntbl[key];
  }

  // hash.c:562
  public function
  rb_hash_default(argc:int, argv:StackPointer, hashv:Value):Value
  {
    var hash:RHash = RHash(hashv);
    var key:Value;

    //rb_scan_args(argc, argv, "01", &key);
    key = argv.get_at(1);
    if ((hash.flags & HASH_PROC_DEFAULT) != 0) {
      if (argc == 0) return rc.Qnil;
      return rc.vm_eval_c.rb_funcall(hash.ifnone, id_yield, 2, hash, key);
    }
    return hash.ifnone;
  }

  // hash.c:987
  public function
  rb_hash_aset(hashv:Value, keyv:Value, val:Value):Value
  {
    var hash:RHash = RHash(hashv);
    rb_hash_modify(hash);
    var key:* = key_from_value(keyv);
    // TODO: @skipped identhash
    if (rc.TYPE(keyv) != Value.T_STRING) {
      hash.ntbl[key] = val;
    } else {
      hash.ntbl[key] = val;
      //hash.ntbl[rc.string_c.rb_str_new4(key)] = val;
    }
    return val;
  }

  // hash.c:2597
  public function
  Init_Hash():void
  {
    id_hash = rc.parse_y.rb_intern("hash");
    id_yield = rc.parse_y.rb_intern("yield");
    id_default = rc.parse_y.rb_intern("default");

    rb_cHash = rc.class_c.rb_define_class("Hash", rc.object_c.rb_cObject);

    // TODO: Lots of hash methods

    rc.class_c.rb_define_method(rb_cHash,"[]", rb_hash_aref, 1);
    rc.class_c.rb_define_method(rb_cHash,"default", rb_hash_default, -1);
    rc.class_c.rb_define_method(rb_cHash,"[]=", rb_hash_aset, 2);
    rc.class_c.rb_define_method(rb_cHash,"store", rb_hash_aset, 2);
  }



}
}
