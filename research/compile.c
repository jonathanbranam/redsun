/*
Research on how 1.9.0-4 is compiling the parsed Ruby and the bytecode that
it emits.
*/

/*

Initial compilation triggered from rt_startup.c when process_options() calls
  rb_iseq_new() and passes in the filename and parse tree.

Compilation appears to be triggered from:
eval_string_with_cref() defined in
  vm_eval.c:669. This calls rb_iseq_compile() from iseq.c:472 which calls
  iseq_compile() in compile.c:204.

iseq_s_compile_file() defined in iseq.c:492


Main compilation method is iseq_compile_each() in compile.c:2659. This method 
loops over the nodes passed in (which I believe are produced from yacc?)
and produces the bytecode necessary for later interpretation. The bytecode
is produced as a linked list (LINK_ANCHOR?) and put into iseq(?). There are
various #defines that append bytecode instructions to the linked list such
as ADD_LABEL, ADD_INSN, ADD_INSN1, etc.

Execution is handled by vm.inc which is generated from insns.def.
*/

// compile.c:2659
static int
iseq_compile_each(rb_iseq_t *iseq, LINK_ANCHOR *ret, NODE * node, int poped)
{
    enum node_type type;

    if (node == 0) {
	if (!poped) {
	    debugs("node: NODE_NIL(implicit)\n");
	    ADD_INSN(ret, iseq->compile_data->last_line, putnil);
	}
	return COMPILE_OK;
    }

    iseq->compile_data->last_line = nd_line(node);
    debug_node_start(node);

    type = nd_type(node);

    if (node->flags & NODE_FL_NEWLINE) {
	ADD_TRACE(ret, nd_line(node), RUBY_EVENT_LINE);
    }

    switch (type) {
      /* Simple example, many more ops are handled here. */
      case NODE_LVAR:{
	if (!poped) {
	    ID id = node->nd_vid;
	    int idx = iseq->local_iseq->local_size - get_local_var_idx(iseq, id);

	    debugs("id: %s idx: %d\n", rb_id2name(id), idx);
	    ADD_INSN1(ret, nd_line(node), getlocal, INT2FIX(idx));
	}
	break;
      }
      default:
	rb_bug("iseq_compile_each: unknown node: %s", ruby_node_name(type));
	return Qnil;
    }

    debug_node_end();
    return COMPILE_OK;
}

/* compile node */
#define COMPILE(anchor, desc, node) \
  (debug_compile("== " desc "\n", \
                 iseq_compile_each(iseq, anchor, node, 0)))


static void
ADD_ELEM(ISEQ_ARG_DECLARE LINK_ANCHOR *anchor, LINK_ELEMENT *elem)
{
    elem->prev = anchor->last;
    anchor->last->next = elem;
    anchor->last = elem;
    verify_list("add", anchor);
}



