package ruby.internals
{
import ruby.RObject;

/**
 * Should be RModule probably.
 */
public dynamic class RModule extends RObject
{
  public static const SINGLETON:int = 1;

  public var context:RClass;
  public var name:String = null;
  //public var rbasic:RBasic = new RBasic();

  //public var iv_tbl:Object = {};
  public var m_tbl:Object = {};
  public var super_class:RClass = null;

  public function RModule(context:RClass=null, name:String = null, super_class:RClass = null, klass:RClass=null)
  {
    super(klass);
    this.context = context;
    this.name = name;
    this.super_class = super_class;
  }

  RClass.prototype.definemethod = function (name:*, block:Function):* {
    var method:RMethod = new RMethod();
    method.body = block;
    method.klass = this;
    this.m_tbl[name] = method;
  }

  RClass.prototype.defineclass = function (name:*, block:Function):* {
    if (super_class == null) {
      super_class = this.send_internal("const_get", "Object");
    }

    var singleton_klass:RClass = new RClass(this, name+"Singleton", super_class.rbasic.klass, this.send_internal("const_get", "Class"));
    singleton_klass.rbasic.flags |= RClass.SINGLETON;

    var klass:RClass = new RClass(name, super_class, singleton_klass);
    klass.super_class = super_class;

    singleton_klass.super_class = super_class.rbasic.klass;
    klass.rbasic.klass = singleton_klass;

    this.send_internal("const_set", name, klass);

    return block.apply(klass);
  }

}
}

