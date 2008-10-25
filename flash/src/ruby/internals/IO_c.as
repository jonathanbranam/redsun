  public var rb_cIO:RClass;

  public var rb_stdout:Value;
  public var rb_default_rs:RString;

  public var id_write:int;

  public function
  Init_IO():void
  {
    rb_define_global_function("puts", rb_f_puts, -1);

    rb_cIO = rb_define_class("IO", rb_cObject);
    // enumerable

    rb_define_method(rb_cIO, "puts", rb_io_puts, -1);

    rb_define_method(rb_cIO, "write", io_write, 1);

    rb_stdout = rb_obj_alloc(rb_cIO);

    rb_default_rs = rb_str_new2("\n");

    id_write = rb_intern("write");
  }

  protected function
  rb_f_puts(argc:int, argv:StackPointer, recv:Value):Value
  {
    if (recv == rb_stdout) {
      return rb_io_puts(argc, argv, recv);
    }
    return rb_funcall2(rb_stdout, rb_intern("puts"), argc, argv);
  }

  public function
  rb_io_puts(argc:int, argv:StackPointer, out:Value):Value
  {
    var i:int;
    var line:RString;

    if (argc == 0) {
      rb_io_write(out, rb_default_rs);
      return Qnil;
    }
    for (i=0; i < argc; i++) {
      line = rb_obj_as_string(argv.get_at(i));
      rb_io_write(out, line);
      // HACK b/c trace spits out newlines all the time.
      if (out != rb_stdout) {
        if (line.string.length == 0 ||
            line.string.charAt(line.string.length-1) != '\n') {
          rb_io_write(out, rb_default_rs);
        }
      }
    }
    return Qnil;
  }

  public function
  rb_io_write(io:Value, str:Value):Value
  {
    return rb_funcall(io, id_write, 1, str);
  }

  protected function
  io_write(io:Value, str:Value):Value
  {
    str = rb_obj_as_string(str);
    if (io == rb_stdout) {
      trace(RString(str).string);
      return Qtrue;
    }

    return Qfalse;
  }

