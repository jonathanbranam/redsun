package ruby.internals
{
public class StackPointer extends Value
{
  public var stack:Array;
  public var index:int;

  public function StackPointer(stack:Array=null, index:int=0)
  {
    if (stack) {
      this.stack = stack;
    } else {
      this.stack = new Array();
    }
    this.index = index;
  }

  public function toString():String {
    return "[StackPointer len="+stack.length+", index="+index+"]";
  }

  public function add_to_index(n:int):void {
    index += n;
  }

  public function set_index(n:int):void {
    index = n;
  }

  public function equals(other:StackPointer):Boolean {
    return (stack == other.stack && index == other.index);
  }

  public function inc(n:int=1):void {
    index += n;
  }

  public function dec(n:int=1):void {
    index -= n;
  }

  public function set_top(val:*):* {
    stack[index] = val;
  }

  public function get_at(offset:int):* {
    return stack[index+offset];
  }

  public function set_at(offset:int, val:*):* {
    stack[index+offset] = val;
    return val;
  }

  public function clone():StackPointer {
    return new StackPointer(stack, index);
  }

  public function pop():* {
    if (index > stack.length) {
      throw new Error("StackPointer pop() error.");
    } else {
      index--;
      //trace("StackPointer pop " + index);
      //return stack[index-1];
      return stack[index];
    }
  }

  public function push(val:*):void {
    if (index > stack.length) {
      throw new Error("StackPointer invalid state.");
    } else if (index == stack.length) {
      stack.push(val);
      index++;
    } else {
      stack[index] = val;
      index++;
      //trace("StackPointer push " + index);
    }
  }

  public function shift():* {
    //trace("StackPointer shift " + (index+1));
    return stack[index++];
  }

  public function popn_destroy(n:int):void {
    index = index-n;
    stack.length = index+1;
  }

  public function popn(n:int):void {
    index = index-n;
    //trace("StackPointer popn " + index);
  }

  public function topn(n:int):* {
    return stack[index-n-1];
  }

  public function set_topn(n:int, val:*):void {
    stack[index-n-1] = val;
  }

  public function clone_from_top(n:int):StackPointer {
    if (n < 0) {
      throw new Error("clone_from_top expects a positive value.");
    }
    return new StackPointer(stack, index-n);
  }

  public function clone_down_stack(n:int):StackPointer {
    if (index+n > stack.length) {
      throw new Error("Increasing stack during clone beyond end!");
    }
    return new StackPointer(stack, index+n);
  }

  public function copy(len:int):Array {
    return stack.slice(index, index+len);
  }

}
}
