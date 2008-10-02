package ruby.internals
{
  import ruby.core.Symbol;


/**
 * Final class for core ruby methods.
 */
public final class RubyCore
{
  public function RubyCore()  {
    throw new Error("RubyCore is a static class.");
  }

  public static function init():void  {
    define_object_prototypes();
    define_ruby_classes();
    define_flash_classes();
  }

  protected static function define_flash_classes():void {

  }

  protected static function define_ruby_classes():void {
    RubyCore.define_class("Class", null, function():* {
    });
    RubyCore.define_class("Object", null, function():* {
    });
  }

  protected static function define_object_prototypes():void {
    Object.prototype.instance_variable_get = function instance_variable_get(name:*):* {
      return this[name];
    }
    Object.prototype.instance_variable_set = function instance_variable_set(name:*, value:*):* {
      return this[name] = value;
    }
    Object.prototype.send_external = function send_external(name:*, ...params):*
    {
      var prop:*;
      // this should just be public
      prop = this[name];
      if (prop != undefined) {
        if (prop is Function) {
          return prop.apply(this, params);
        } else {
          return prop;
        }
      } else {
        throw new Error("NoMethodError: undefined method '"+name+"' for typed class "+this);
      }
    }
  }

  public static function define_class(name:String, super_class:RClass, block:Function):* {
    var klass:RClass = new RClass(name, super_class);
    klass.rbasic.klass = RClass;
    RGlobal.global.const_set(name, klass);
  }

}
}
