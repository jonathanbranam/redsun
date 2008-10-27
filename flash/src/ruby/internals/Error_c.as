
  import ruby.internals.Value;
    public var rb_eException:RClass;

  public var rb_eSystemExit:RClass;

  public var rb_eFatal:RClass;
  public var rb_eSignal:RClass;
  public var rb_eInterrupt:RClass;

  public var rb_eStandardError:RClass;
  public var rb_eTypeError:RClass;
  public var rb_eArgError:RClass;
  public var rb_eIndexError:RClass;
  public var rb_eKeyError:RClass;
  public var rb_eRangeError:RClass;
  public var rb_eEncCompatError:RClass;

  public var rb_eScriptError:RClass;
  public var rb_eSyntaxError:RClass;
  public var rb_eLoadError:RClass;
  public var rb_eNotImpError:RClass;

  public var rb_eNameError:RClass;
  public var rb_cNameErrorMesg:RClass;

  public var rb_eNoMethodError:RClass;

  public var rb_eRuntimeError:RClass;
  public var rb_eSecurityError:RClass;
  public var rb_eNoMemError:RClass;

  public var rb_eSystemCallError:RClass;

  public function Init_Exception():void {
    rb_eException = rb_define_class("Exception", rb_cObject);
    // exception methods

    rb_eSystemExit = rb_define_class("SystemExit", rb_eException);
    rb_eFatal = rb_define_class("fatal", rb_eException);
    rb_eSignal = rb_define_class("SignalException", rb_eException);
    rb_eInterrupt = rb_define_class("Interrupt", rb_eSignal);

    rb_eStandardError = rb_define_class("StandardError", rb_eException);
    rb_eTypeError = rb_define_class("TypeError", rb_eStandardError);
    rb_eArgError = rb_define_class("ArgumentError", rb_eStandardError);
    rb_eIndexError = rb_define_class("IndexError", rb_eStandardError);
    rb_eKeyError = rb_define_class("KeyError", rb_eIndexError);
    rb_eRangeError = rb_define_class("RangeError", rb_eStandardError);
    rb_eEncCompatError = rb_define_class("EncodingCompatibilityError", rb_eStandardError);

    rb_eScriptError = rb_define_class("ScriptError", rb_eException);
    rb_eSyntaxError = rb_define_class("SyntaxError", rb_eScriptError);
    rb_eLoadError = rb_define_class("LoadError", rb_eScriptError);
    rb_eNotImpError = rb_define_class("NotImplementedError", rb_eScriptError);

    rb_eNameError = rb_define_class("NameError", rb_eStandardError);
    rb_cNameErrorMesg = rb_define_class_under(rb_eNameError, "message", rb_cData);

    rb_eNoMethodError = rb_define_class("NoMethodError", rb_eNameError);

    rb_eRuntimeError = rb_define_class("RuntimeError", rb_eStandardError);
    rb_eSecurityError = rb_define_class("SecurityError", rb_eException);
    rb_eNoMemError = rb_define_class("NoMemoryError", rb_eException);

    rb_eSystemCallError = rb_define_class("SystemCallError", rb_eStandardError);

    rb_define_global_function("warn", rb_warn_m, 1);

  }

  // error.c:190
  protected function
  rb_warn_m(self:Value, mesg:Value):Value
  {
    // if (!NIL_P(ruby_verbose)) {
      trace(mesg);
      //trace(rb_default_rs);
    // }
    return Qnil;
  }

  public function
  rb_raise(type:RClass, desc:String):void
  {
    throw new Error(type.toString() + desc);
  }

  public function
  rb_warn(text:String):void
  {
    trace(text);
  }

  public function
  rb_error_frozen(text:String):void
  {
    throw new Error("Frozen " + text);
  }

  public function
  rb_bug(message:String):void
  {
    throw new Error("rb_bug: " + message);
  }

  // error.c:621
  public function
  rb_name_error(id:int, str:String):void
  {
    // This isn't right at all
    rb_raise(rb_eNameError, str);
  }

  // error.c:244
  protected var builtin_types:Array =
  [
    {type:Value.T_NIL,      name:"nil"},
    {type:Value.T_OBJECT,   name:"Object"},
    {type:Value.T_CLASS,    name:"Class"},
    {type:Value.T_ICLASS,   name:"iClass"},
    {type:Value.T_MODULE,   name:"Module"},
    {type:Value.T_FLOAT,    name:"Float"},
    {type:Value.T_STRING,   name:"String"},
    {type:Value.T_REGEXP,   name:"Regexp"},
    {type:Value.T_ARRAY,    name:"Array"},
    {type:Value.T_FIXNUM,   name:"Fixnum"},
    {type:Value.T_HASH,     name:"Hash"},
    {type:Value.T_STRUCT,   name:"Struct"},
    {type:Value.T_BIGNUM,   name:"Bignum"},
    {type:Value.T_FILE,     name:"File"},
    {type:Value.T_RATIONAL, name:"Rational"},
    {type:Value.T_COMPLEX,  name:"Complex"},
    {type:Value.T_TRUE,     name:"true"},
    {type:Value.T_FALSE,    name:"false"},
    {type:Value.T_SYMBOL,   name:"Symbol"},
    {type:Value.T_DATA,     name:"Data"},
    {type:Value.T_MATCH,    name:"MatchData"},
    {type:Value.T_NODE,     name:"Node"},
    {type:Value.T_UNDEF,    name:"undef"},
  ];

  // error.c:271
  public function
  rb_check_type(x:Value, t:int):void
  {
    var types:Array = builtin_types;

    if (x == Qundef) {
      rb_bug("undef leaked to the Ruby space");
    }

    if (TYPE(x) != t) {
      for each (var type:* in types) {
        if (type.type == t) {
          var etype:String;

          if (NIL_P(x)) {
            etype = "nil";
          }
          else if (FIXNUM_P(x)) {
            etype = "Fixnum";
          }
          else if (SYMBOL_P(x)) {
            etype = "Symbol";
          }
          else if (rb_special_const_p(x)) {
            etype = RSTRING_PTR(rb_obj_as_string(x));
          }
          else {
            etype = rb_obj_classname(x);
          }
          rb_raise(rb_eTypeError, "wrong argument type " + etype + " (expected "+type.name+")");
        }
      }
      rb_bug("unknown type 0x"+t.toString(16)+" (0x"+TYPE(x).toString(16)+" given)");
    }
  }


