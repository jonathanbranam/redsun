package ruby.internals
{
import flash.display.DisplayObject;

import ruby.RObject;


/**
 * Final class for core ruby methods.
 */
public final class RubyCore
{
  public function RubyCore()  {
    throw new Error("RubyCore is a static class.");
  }

  public static function run(docClass:DisplayObject, block:Function):void  {
    init();
    RGlobal.global.send_external(null, "const_set", "Document", docClass);
    RGlobal.global.send_external(null, "module_eval", block);
  }

  public static function init():void  {
    define_object_prototypes();
    define_ruby_classes();
    define_flash_classes();
  }

  protected static function define_flash_classes():void {
    RubyCore.define_class("Flash",
      RGlobal.global.send_external(null, "const_get", "Object"),
      function ():* {
      });
  }

  protected static function define_ruby_classes():void {


    var basic_object_singleton_klass:RClass = new RClass("BasicObjectSingleton", null);
    basic_object_singleton_klass.rbasic.flags |= RClass.SINGLETON;
    var basic_object:RClass = new RClass("BasicObject", null, basic_object_singleton_klass);

    var object_singleton_klass:RClass = new RClass("ObjectSingleton", basic_object_singleton_klass);
    object_singleton_klass.rbasic.flags |= RClass.SINGLETON;
    var object:RClass = new RClass("Object", basic_object, object_singleton_klass);

    var module_singleton_klass:RClass = new RClass("ModuleSingleton", object_singleton_klass);
    module_singleton_klass.rbasic.flags |= RClass.SINGLETON;
    var module:RClass = new RClass("Module", object, module_singleton_klass);

    var klass_singleton_klass:RClass = new RClass("ClassSingleton", module_singleton_klass);
    klass_singleton_klass.rbasic.flags |= RClass.SINGLETON;
    var klass:RClass = new RClass("Class", module, klass_singleton_klass);

    basic_object_singleton_klass.rbasic.klass = klass;
    basic_object_singleton_klass.super_class = klass;
    object_singleton_klass.rbasic.klass = klass;
    module_singleton_klass.rbasic.klass = klass;
    klass_singleton_klass.rbasic.klass = klass;

    basic_object.definemethod("method_missing", function (name:*, ...params):* {
      throw new Error("NoMethodError: undefined method  '" + name + "' for " + this);
    });

    basic_object.definemethod("define_singleton_method", function (name:*, block:Function):* {
      var klass:RClass = this.rbasic.klass;
      if ((klass.rbasic.flags & RClass.SINGLETON) == 0) {
        klass = new RClass("Singleton", this.rbasic.klass, RGlobal.global.send_external(this, "const_get", "Class"));
        klass.rbasic.flags |= RClass.SINGLETON;
        this.rbasic.klass = klass;
      }
      klass.definemethod(name, block);
    });

    basic_object.defineclassmethod("const_missing", function (name:*, ...params):* {
      throw new Error("NameError: uninitialized constant " + name);
    });

    basic_object.defineclassmethod("const_get", function (name:*):* {
      var const_value:* = this.iv_tbl[name];

      var context:RClass = this.context;
      while (const_value == undefined && context != null) {
        const_value = context.iv_tbl[name];
        if (method != undefined) {
          return method;
        }
        klass = klass.super_class;
      }
      if (!klass) {
        return null;
      }
      return null;


      if (const_value != undefined) {
        return const_value;
      } else {
        return this.send_internal("const_missing", name);
      }
    });
    basic_object.defineclassmethod("const_set", function (name:*, value:*):* {
      return this.iv_tbl[name] = value;
    });

    basic_object.definemethod("instance_variable_get", function (name:*):* {
      return this.iv_tbl[name];
    });
    basic_object.definemethod("instance_variable_set", function (name:*, value:*):* {
      return this.iv_tbl[name] = value;
    });

    basic_object.definemethod("initialize", function ():* {
    });

    basic_object.defineclassmethod("module_eval", function (block:*):* {
      block.apply(this);
    });

    basic_object.definemethod("instance_eval", function (block:*):* {
      block.apply(this);
    });

    klass.definemethod("allocate", function ():* {
      return new RObject(this);
    });

    klass.definemethod("new", function (...params):* {
      var obj:RObject = this.send_internal("allocate");
      obj.send_internal.apply(obj, ["initialize"].concat(params));
      return obj;
    });

    RGlobal.global = new RGlobal(object);
    RGlobal.global.send_external(null, "const_set", "BasicObject", basic_object);
    RGlobal.global.send_external(null, "const_set", "Object", object);
    RGlobal.global.send_external(null, "const_set", "Module", module);
    RGlobal.global.send_external(null, "const_set", "Class", klass);

  }

  protected static function define_object_prototypes():void {
    Object.prototype.instance_variable_get = function instance_variable_get(name:*):* {
      return this[name];
    }
    Object.prototype.instance_variable_set = function instance_variable_set(name:*, value:*):* {
      return this[name] = value;
    }
    Object.prototype.send_external = function send_external(context:*, name:*, ...params):*
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
    if (super_class == null) {
      super_class = RGlobal.global.send_external(null, "const_get", "Object");
    }

    var singleton_klass:RClass = new RClass(name+"Singleton", super_class.rbasic.klass, RGlobal.global.send_external(null, "const_get", "Class"));
    singleton_klass.rbasic.flags |= RClass.SINGLETON;

    var klass:RClass = new RClass(name, super_class, singleton_klass);
    klass.super_class = super_class;

    singleton_klass.super_class = super_class.rbasic.klass;
    klass.rbasic.klass = singleton_klass;

    RGlobal.global.send_external(null, "const_set", name, klass);

    return block.apply(klass);
  }

}
}

