package ruby.internals
{
public class Error_c
{

  public var rc:RubyCore;

  import ruby.internals.RObject;
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
    rb_eException = rc.class_c.rb_define_class("Exception", rc.object_c.rb_cObject);
    // exception methods

    rb_eSystemExit = rc.class_c.rb_define_class("SystemExit", rb_eException);
    rb_eFatal = rc.class_c.rb_define_class("fatal", rb_eException);
    rb_eSignal = rc.class_c.rb_define_class("SignalException", rb_eException);
    rb_eInterrupt = rc.class_c.rb_define_class("Interrupt", rb_eSignal);

    rb_eStandardError = rc.class_c.rb_define_class("StandardError", rb_eException);
    rc.error_c.rb_eTypeError = rc.class_c.rb_define_class("TypeError", rb_eStandardError);
    rc.error_c.rb_eArgError = rc.class_c.rb_define_class("ArgumentError", rb_eStandardError);
    rb_eIndexError = rc.class_c.rb_define_class("IndexError", rb_eStandardError);
    rb_eKeyError = rc.class_c.rb_define_class("KeyError", rb_eIndexError);
    rb_eRangeError = rc.class_c.rb_define_class("RangeError", rb_eStandardError);
    rb_eEncCompatError = rc.class_c.rb_define_class("EncodingCompatibilityError", rb_eStandardError);

    rb_eScriptError = rc.class_c.rb_define_class("ScriptError", rb_eException);
    rb_eSyntaxError = rc.class_c.rb_define_class("SyntaxError", rb_eScriptError);
    rb_eLoadError = rc.class_c.rb_define_class("LoadError", rb_eScriptError);
    rb_eNotImpError = rc.class_c.rb_define_class("NotImplementedError", rb_eScriptError);

    rb_eNameError = rc.class_c.rb_define_class("NameError", rb_eStandardError);
    rb_cNameErrorMesg = rc.class_c.rb_define_class_under(rb_eNameError, "message", rc.object_c.rb_cData);

    rb_eNoMethodError = rc.class_c.rb_define_class("NoMethodError", rb_eNameError);

    rb_eRuntimeError = rc.class_c.rb_define_class("RuntimeError", rb_eStandardError);
    rb_eSecurityError = rc.class_c.rb_define_class("SecurityError", rb_eException);
    rb_eNoMemError = rc.class_c.rb_define_class("NoMemoryError", rb_eException);

    rb_eSystemCallError = rc.class_c.rb_define_class("SystemCallError", rb_eStandardError);

    rc.class_c.rb_define_global_function("warn", rc.error_c.rb_warn_m, 1);

  }

  // error.c:190
  protected function
  rb_warn_m(self:Value, mesg:Value):Value
  {
    // if (!NIL_P(ruby_verbose)) {
      trace(mesg);
      //trace(rb_default_rs);
    // }
    return rc.Qnil;
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
    throw new Error("rc.error_c.rb_bug: " + message);
  }

  // error.c:621
  public function
  rb_name_error(id:int, str:String):void
  {
    // This isn't right at all
    rc.error_c.rb_raise(rb_eNameError, str);
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

    if (x == rc.Qundef) {
      rc.error_c.rb_bug("undef leaked to the Ruby space");
    }

    if (rc.TYPE(x) != t) {
      for each (var type:* in types) {
        if (type.type == t) {
          var etype:String;

          if (rc.NIL_P(x)) {
            etype = "nil";
          }
          else if (rc.FIXNUM_P(x)) {
            etype = "Fixnum";
          }
          else if (rc.SYMBOL_P(x)) {
            etype = "Symbol";
          }
          else if (rc.rb_special_const_p(x)) {
            etype = rc.RSTRING_PTR(rc.string_c.rb_obj_as_string(x));
          }
          else {
            etype = rc.variable_c.rb_obj_classname(x);
          }
          rc.error_c.rb_raise(rc.error_c.rb_eTypeError, "wrong argument type " + etype + " (expected "+type.name+")");
        }
      }
      rc.error_c.rb_bug("unknown type 0x"+t.toString(16)+" (0x"+rc.TYPE(x).toString(16)+" given)");
    }
  }

  // error.c:342
  public function
  rb_exc_new(etype:Value, ptr:String):RObject
  {
    return RObject(rc.vm_eval_c.rb_funcall(etype, rc.rc.parse_y.rb_intern("new"), 1, rc.string_c.rb_str_new(ptr)));
  }


  // error.c:348
  public function
  rb_exc_new2(etype:Value, s:String):RObject
  {
    return rb_exc_new(etype, s);
  }

}

}
