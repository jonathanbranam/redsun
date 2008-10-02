package ruby
{
import ruby.internals.RBasic;
import ruby.internals.RClass;
import ruby.internals.RGlobal;
import ruby.internals.RMethod;

public class RObject
{
  public var rbasic:RBasic;
  public var rclass:RClass;
  public var rglobal:RGlobal;
  public var iv_tbl:Object = {};

  RObject.prototype.instance_vars = {}
  RObject.prototype.instance_variable_get = function instance_variable_get(name:*):* {
    return iv_tbl[name];
  }
  RObject.prototype.instance_variable_set = function instance_variable_set(name:*, value:*):* {
    return iv_tbl[name] = value;
  }
  RObject.prototype.const_missing = function const_missing(name:*):* {
    throw new Error("NameError: uninitialized constant " + name);
  }
  RObject.prototype.const_get = function const_get(name:*):* {
    var const_value:* = iv_tbl[name];
    if (const_value != undefined) {
      return const_value;
    } else {
      return this.send_internal("const_missing", name);
    }
  }
  RObject.prototype.const_set = function const_set(name:*, value:*):* {
    return iv_tbl[name] = value;
  }
  protected function search_method(name:String):RMethod
  {
    var klass:RClass = rclass;
    while (klass) {
      var method:* = klass[name];
      if (method != undefined) {
        return method;
      }
      klass = klass.super_class;
    }
    if (!klass) {
      return null;
    }
  }
  RObject.prototype.is_a_Q = function is_a_Q(klass:*):* {
    var klass:RClass = rclass;
    while (klass) {
      if (this.rbasic.klass == klass) {
        return true;
      }
      klass = klass.super_class;
    }
    return false;
  }
  RObject.prototype.kind_of_Q = RObject.prototype.is_a_Q;

  RObject.prototype.method_missing = function method_missing(name:*, ...params):* {
    throw new Error("NoMethodError: undefined method  '" + name + "' for " + this);
  }
  RObject.prototype.send_internal = function send_internal(name:*, ...params):*
  {
    var method:RMethod = search_method(name);

    // Allow private/protected calls

    if (method != null) {
      return method.body.apply(this, params);
    } else {
      var new_params:Array = ["method_missing", name].concat(params);
      return this.send_internal.apply(this, new_params);
    }
  }
  RObject.prototype.send_external = function send_external(context:*, name:*, ...params):*
  {
    var method:RMethod = search_method(name);

    var canCall:Boolean = false;

    if (method != null) {
      // Allow calls if not private or protected
      if ((method.flags && RMethod.PRIVATE == 0) && (method.flags && RMethod.PROTECTED == 0)) {
        canCall = true;
      }

      if (method.flags && RMethod.PROTECTED != 0) {
        if (context is RObject) {
          if (RObject(context).is_a_Q(method.klass)) {
            canCall = true;
          }
        }
      }
    }

    if (canCall) {
      return method.body.apply(this, params);
    } else {
      var new_params:Array = ["method_missing", name].concat(params);
      return this.send_internal.apply(this, new_params);
    }
  }



  public function RObject()
  {
  }

}
}
