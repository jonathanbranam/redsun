package ruby.internals
{
import flash.utils.Proxy;
import flash.utils.flash_proxy;

public class RProxy extends Proxy
{
  protected var rc:RubyCore;
  protected var value:Value;

  public function RProxy(rc:RubyCore, value:Value)
  {
    super();
    this.rc = rc;
    this.value = value;
  }

  flash_proxy override function callProperty(name:*, ...rest):*
  {
    rc.vm_eval_c.rb_funcall2(value, rc.rc.parse_y.rb_intern(name.toString()), rest.length, rc.convert_to_ruby_value(rest));
  }

  flash_proxy override function getProperty(name:*):*
  {
    if (name == "ruby_value") {
      return value;
    }
    rc.vm_eval_c.rb_funcall(value, rc.rc.parse_y.rb_intern(name.toString()), 0);
  }

  flash_proxy override function setProperty(name:*, value:*):void
  {
    rc.vm_eval_c.rb_funcall(value, rc.rc.parse_y.rb_intern(name.toString()+"="), 1, rc.convert_to_as3(value));
  }

}
}
