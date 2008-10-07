package ruby
{
import ruby.internals.RBasic;
import ruby.internals.RClass;
import ruby.internals.RMethod;

public dynamic class RObject
{
  public var rbasic:RBasic = new RBasic();
  public var iv_tbl:Object = {};

  protected function search_method(name:String):RMethod
  {
    var klass:RClass = this.rbasic.klass;
    while (klass) {
      var method:* = klass.m_tbl[name];
      if (method != undefined) {
        return method;
      }
      klass = klass.super_class;
    }
    if (!klass) {
      return null;
    }
    return null;
  }
  RObject.prototype.is_a_Q = function is_a_Q(klass:*):* {
    var klass:RClass = this.rbasic.klass;
    while (klass) {
      if (this.rbasic.klass == klass) {
        return true;
      }
      klass = klass.super_class;
    }
    return false;
  }
  RObject.prototype.kind_of_Q = RObject.prototype.is_a_Q;

  RObject.prototype.send_internal = function send_internal(name:*, ...params):*
  {
    var method:RMethod = this.search_method(name);

    // Allow private/protected calls

    if (method != null) {
      return method.body.apply(this, params);
    } else {
      if (name == "method_missing") {
        throw new Error("method_missing Method Missing.");
      }
      var new_params:Array = ["method_missing", name];
      new_params = new_params.concat(params);
      return this.send_internal.apply(this, new_params);
    }
  }
  RObject.prototype.send_external = function send_external(context:*, name:*, ...params):*
  {
    var method:RMethod = this.search_method(name);

    var canCall:Boolean = false;

    if (method != null) {
      // Allow calls if not private or protected
      if (((method.flags & RMethod.PRIVATE) == 0) && ((method.flags & RMethod.PROTECTED) == 0)) {
        canCall = true;
      }

      if ((method.flags & RMethod.PROTECTED) != 0) {
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



  public function RObject(klass:RClass=null)
  {
    rbasic.klass = klass;
  }

}
}
