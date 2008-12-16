package ruby.internals
{
public class RbISeq extends Node
{
  public var type:uint;
  public var name:Value;
  public var filename:Value;
  public var iseq:Array;
  public var iseq_encoded:Array;
  public var iseq_fn:Function;
  public var iseq_size:uint;
  public var mark_ary:Value;
  public var coverage:Value;

  public var insn_info_table:*;
  public var insn_info_size:int;

  public var local_table:Array;
  public var local_table_size:int;

  public var local_size:int;

  public var argc:int;
  public var arg_simple:int;
  public var arg_rest:int;
  public var arg_block:int;
  public var arg_opts:int;
  public var arg_post_len:int;
  public var arg_post_start:int;
  public var arg_size:int;
  public var arg_opt_table:Array;

  public var stack_max:int;

  public var catch_table:Array;
  public var catch_table_size:int;

  public var parent_iseq:RbISeq;
  public var local_iseq:RbISeq;

  public var self:Value;
  public var orig:Value;

  // Linked list of Nodes
  public var cref_stack:Node;
  public var klass:RClass;

  public var defined_method_id:int;
  public var profile:*;

  public var compile_data:*;


  public function RbISeq()
  {
  }

}
}
