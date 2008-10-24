
  import ruby.internals.RNumber;
  import ruby.internals.Value;

  public function
  INT2FIX(i:int):Value
  {
    return new RInt(i);
  }

  public function
  NUM2NUM(v:Number):Value
  {
    return new RNumber(v);
  }
