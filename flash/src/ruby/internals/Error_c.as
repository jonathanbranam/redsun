package ruby.internals
{
public class Error_c
{
  protected var rc:RubyCore;

  public var object_c:Object_c;
  public var class_c:Class_c;

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

  public function Error_c(rc:RubyCore)
  {
    this.rc = rc;
  }

  public function Init_Exception():void {
    rb_eException = class_c.rb_define_class("Exception", object_c.rb_cObject);
    // exception methods

    rb_eSystemExit = class_c.rb_define_class("SystemExit", rb_eException);
    rb_eFatal = class_c.rb_define_class("fatal", rb_eException);
    rb_eSignal = class_c.rb_define_class("SignalException", rb_eException);
    rb_eInterrupt = class_c.rb_define_class("Interrupt", rb_eSignal);

    rb_eStandardError = class_c.rb_define_class("StandardError", rb_eException);
    rb_eTypeError = class_c.rb_define_class("TypeError", rb_eStandardError);
    rb_eArgError = class_c.rb_define_class("ArgumentError", rb_eStandardError);
    rb_eIndexError = class_c.rb_define_class("IndexError", rb_eStandardError);
    rb_eKeyError = class_c.rb_define_class("KeyError", rb_eIndexError);
    rb_eRangeError = class_c.rb_define_class("RangeError", rb_eStandardError);
    rb_eEncCompatError = class_c.rb_define_class("EncodingCompatibilityError", rb_eStandardError);

    rb_eScriptError = class_c.rb_define_class("ScriptError", rb_eException);
    rb_eSyntaxError = class_c.rb_define_class("SyntaxError", rb_eScriptError);
    rb_eLoadError = class_c.rb_define_class("LoadError", rb_eScriptError);
    rb_eNotImpError = class_c.rb_define_class("NotImplementedError", rb_eScriptError);

    rb_eNameError = class_c.rb_define_class("NameError", rb_eStandardError);
    rb_cNameErrorMesg = class_c.rb_define_class_under(rb_eNameError, "message", object_c.rb_cData);

    rb_eNoMethodError = class_c.rb_define_class("NoMethodError", rb_eNameError);

    rb_eRuntimeError = class_c.rb_define_class("RuntimeError", rb_eStandardError);
    rb_eSecurityError = class_c.rb_define_class("SecurityError", rb_eException);
    rb_eNoMemError = class_c.rb_define_class("NoMemoryError", rb_eException);

    rb_eSystemCallError = class_c.rb_define_class("SystemCallError", rb_eStandardError);

    class_c.rb_define_global_function("warn", rb_warn_m, 1);

  }

  // error.c:190
  protected function
  rb_warn_m(self:Value, mesg:Value):Value
  {
    // if (!NIL_P(rc.ruby_verbose)) {
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
    throw new Error("rb_bug: " + message);
  }

  // error.c:621
  public function
  rb_name_error(id:int, str:String):void
  {
    // This isn't right at all
    rb_raise(rb_eNameError, str);
  }


}
}
