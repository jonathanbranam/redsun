  // gc.c:985
  public function
  rb_node_newnode(type:uint, a0:*, a1:*, a2:*):Node
  {
    var n:Node = new Node();//rb_newobj();

    n.flags |= Value.T_NODE;
    n.nd_set_type(type);

    n.u1 = a0;
    n.u2 = a1;
    n.u3 = a2;

    return n;
  }

  // gc.c:1000
  public function
  rb_data_object_alloc(klass:RClass, datap:*, dmark:Function, dfree:Function):Value
  {
    var data:RData = new RData(klass);

    data.flags = Value.T_DATA;
    data.data = datap;
    data.dfree = dfree;
    data.dmark = dmark;

    return data;
  }

  // gc.c:2099
  public function
  Init_heap():void
  {
    // TODO: @skipped init_heap()
  }


