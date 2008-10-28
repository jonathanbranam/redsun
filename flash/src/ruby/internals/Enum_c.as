package ruby.internals
{
public class Enum_c
{
  public var rc:RubyCore;

  public var rb_mEnumerable:RClass;

  public var id_each:int;

  // enum.c:20
  public function
  enum_values_pack(argc:int, argv:StackPointer):Value
  {
    if (argc == 0) return rc.Qnil;
    if (argc == 1) return argv.get_at(0);
    return rc.array_c.rb_ary_new4(argc, argv);
  }

  // enum.c:1804
  public function
  Init_Enumerable():void
  {
    rb_mEnumerable = rc.class_c.rb_define_module("Enumerable");

    rc.class_c.rb_define_method(rb_mEnumerable, "to_a", enum_to_a, -1);

    id_each = rc.parse_y.rb_intern_const("id_each");
  }

  // enum.c:363
  public function
  collect_all(i:Value, ary:Value, argc:int, argv:StackPointer):Value
  {
    rc.array_c.rb_ary_push(RArray(ary), enum_values_pack(argc, argv));

    return rc.Qnil;
  }

  // enum.c:407
  public function
  enum_to_a(argc:int, argv:StackPointer, obj:Value):Value
  {
    var ary:RArray = rc.array_c.rb_ary_new();

    rc.vm_eval_c.rb_block_call(obj, id_each, argc, argv, collect_all, ary);

    return ary;
  }

}
}
