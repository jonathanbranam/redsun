package ruby.internals
{
public class Error_c
{
  protected var rc:RubyCore;

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
    rb_eException = rc.rb_define_class("Exception", rc.rb_cObject);
    // exception methods

    rb_eSystemExit = rc.rb_define_class("SystemExit", rb_eException);
    rb_eFatal = rc.rb_define_class("fatal", rb_eException);
    rb_eSignal = rc.rb_define_class("SignalException", rb_eException);
    rb_eInterrupt = rc.rb_define_class("Interrupt", rb_eSignal);

    rb_eStandardError = rc.rb_define_class("StandardError", rb_eException);
    rb_eTypeError = rc.rb_define_class("TypeError", rb_eStandardError);
    rb_eArgError = rc.rb_define_class("ArgumentError", rb_eStandardError);
    rb_eIndexError = rc.rb_define_class("IndexError", rb_eStandardError);
    rb_eKeyError = rc.rb_define_class("KeyError", rb_eIndexError);
    rb_eRangeError = rc.rb_define_class("RangeError", rb_eStandardError);
    rb_eEncCompatError = rc.rb_define_class("EncodingCompatibilityError", rb_eStandardError);

    rb_eScriptError = rc.rb_define_class("ScriptError", rb_eException);
    rb_eSyntaxError = rc.rb_define_class("SyntaxError", rb_eScriptError);
    rb_eLoadError = rc.rb_define_class("LoadError", rb_eScriptError);
    rb_eNotImpError = rc.rb_define_class("NotImplementedError", rb_eScriptError);

    rb_eNameError = rc.rb_define_class("NameError", rb_eStandardError);
    //rb_cNameErrorMesg = rc.rb_define_class_under(rb_eNameError, "message", rc.rb_cData);

    rb_eNoMethodError = rc.rb_define_class("NoMethodError", rb_eNameError);

    rb_eRuntimeError = rc.rb_define_class("RuntimeError", rb_eStandardError);
    rb_eSecurityError = rc.rb_define_class("SecurityError", rb_eException);
    rb_eNoMemError = rc.rb_define_class("NoMemoryError", rb_eException);

    rb_eSystemCallError = rc.rb_define_class("SystemCallError", rb_eStandardError);

    rc.rb_define_global_function("warn", rb_warn_m, 1);

  }

  // error.c:190
  protected function rb_warn_m(self:Value, mesg:Value):Value {
    // if (!NIL_P(rc.ruby_verbose)) {
      trace(mesg);
      //trace(rb_default_rs);
    // }
    return rc.Qnil;
  }

}
}
