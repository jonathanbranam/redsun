package
{
  public class FixNum
  {
    public function FixNum(value:*)
    {
      this.value = value;
    }

    prototype.lte = function (other:*):* {
      return this.value <= other.value;
    }

    prototype.plus = function (other:*):* {
      return new FixNum(this.value + other.value);
    }

    prototype.upto = function(end:*, f:Function):* {
      for (var i:FixNum = new FixNum(this.value); i.lte(end); i = i.plus(1)) {
        f(i);
      }
    }

  }
}