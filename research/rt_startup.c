/*
Tracing initial ruby execution:
*/

// main.c:23
void main(int argc, char **argv) {
  ruby_set_debug_option(getenv("RUBY_DEBUG"));
  ruby_sysinit(&argc, &argv);
  RUBY_INIT_STACK;
  ruby_init();
  ruby_run_node(ruby_options(argc, argv));
}

// eval.c:48
void ruby_init() {
  Init_stack(&state); // C Stack setup code
  Init_BareVM();
  Init_heap(); // C heap management, malloc, realloc, etc
  PUSH_TAG();
  EXEC_TAG();
  rb_call_inits();
  ruby_prog_init();
  POP_TAG;
}

// eval_intern.h:132
#define TH_PUSH_TAG(th) do { \
  rb_thread_t * const _th = th; \
  struct rb_vm_tag _tag; \
  _tag.tag = 0; \
  _tag.prev = _th->tag; \
  _th->tag = &_tag;

#define TH_POP_TAG() \
  _th->tag = _tag.prev; \
} while (0)

#define PUSH_TAG() TH_PUSH_TAG(GET_THREAD())
#define POP_TAG()      TH_POP_TAG()

#define TH_EXEC_TAG() ruby_setjmp(_th->tag->buf)

#define EXEC_TAG() \
  TH_EXEC_TAG()

#define TH_JUMP_TAG(th, st) do { \
  ruby_longjmp(th->tag->buf,(st)); \
} while (0)

#define JUMP_TAG(st) TH_JUMP_TAG(GET_THREAD(), st)


// vm.c:1910
void Init_BareVM(void) {
    /* VM bootstrap: phase 1 */
    rb_vm_t * vm = malloc(sizeof(*vm));
    rb_thread_t * th = malloc(sizeof(*th));
    MEMZERO(th, rb_thread_t, 1);

    rb_thread_set_current_raw(th); // set some globals

    vm->objspace = rb_objspace_alloc(); // alloc + init
    ruby_current_vm = vm;

    th_init2(th, 0);
    th->vm = vm;
    ruby_thread_init_stack(th); // native thread management
}

// vm.c:1587
static void
th_init2(rb_thread_t *th, VALUE self)
{
    th->self = self;

    /* allocate thread stack */
    th->stack_size = RUBY_VM_THREAD_STACK_SIZE;
    th->stack = thread_recycle_stack(th->stack_size);

    th->cfp = (void *)(th->stack + th->stack_size);

    vm_push_frame(th, 0, VM_FRAME_MAGIC_TOP, Qnil, 0, 0,
		  th->stack, 0, 1);

    th->status = THREAD_RUNNABLE;
    th->errinfo = Qnil;
    th->last_status = Qnil;

#if USE_VALUE_CACHE
    th->value_cache_ptr = &th->value_cache[0];
#endif
}



//eval.c:233
void ruby_run_node(VALUE n) {
  Init_stack(n);
  ruby_cleanup(ruby_exec_node(n, 0));
}

//eval.c:207
void ruby_exec_node(VALUE n, char *file) {
  PUSH_TAG();
  EXEC_TAG();
  rb_iseq_eval(n);
  POP_TAG();
  return state;
}

//vm.c:1256
void rb_iseq_eval(VALUE iseqval) {
  vm_set_top_stack(GET_THREAD(), iseqval);
  rb_define_global_const("TOPLEVEL_BINDING", rb_binding_new());
  return vm_eval_body(th);
}

//vm.c:1051
void vm_eval_body(rb_thread_t *th) {
  TH_PUSH_TAG(th);
  state = EXEC_TAG();
  result = vm_eval(th, initial);
  if (th->state != 0) goto exception_handler;
  //COMPLICATED EXCEPTION HANDLING
  TH_POP_TAG();
  return result;
}

/*
vm_eval() is defined in vm_evalbody.c and #includes "vm.inc" and "vmtc.inc"
which are apparently generated files of some kind. There are two options,
one appears to execute code directly and the other looks up the instruction
somehow and dispatches a method to handle it.
*/

// vm_evalbody.c:119
vm_eval(rb_thread_t *th, VALUE initial)
{
    register rb_control_frame_t *reg_cfp = th->cfp;
    VALUE ret;

    while (*GET_PC()) {
	reg_cfp = ((rb_insn_func_t) (*GET_PC()))(th, reg_cfp);

	if (reg_cfp == 0) {
	    VALUE err = th->errinfo;
	    th->errinfo = Qnil;
	    return err;
	}
    }

    if (VM_FRAME_TYPE(th->cfp) != VM_FRAME_MAGIC_FINISH) {
	rb_bug("cfp consistency error");
    }

    ret = *(th->cfp->sp-1); /* pop */
    th->cfp++; /* pop cf */
    return ret;
}
