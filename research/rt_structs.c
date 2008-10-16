/*
Important Ruby structs
*/

//vm_core.h:343
typedef struct {
    VALUE *pc;			/* cfp[0] */
    VALUE *sp;			/* cfp[1] */
    VALUE *bp;			/* cfp[2] */
    rb_iseq_t *iseq;		/* cfp[3] */
    VALUE flag;			/* cfp[4] */
    VALUE self;			/* cfp[5] / block[0] */
    VALUE *lfp;			/* cfp[6] / block[1] */
    VALUE *dfp;			/* cfp[7] / block[2] */
    rb_iseq_t *block_iseq;	/* cfp[8] / block[3] */
    VALUE proc;			/* cfp[9] / block[4] */
    ID method_id;               /* cfp[10] saved in special case */
    VALUE method_class;         /* cfp[11] saved in special case */
    VALUE prof_time_self;       /* cfp[12] */
    VALUE prof_time_chld;       /* cfp[13] */
} rb_control_frame_t;

// control frame generally cref?

//vm_core.h:293
typedef struct rb_iseq_struct rb_iseq_t;

//vm_core.h:192
struct rb_iseq_struct {
    /***************/
    /* static data */
    /***************/

    VALUE type;          /* instruction sequence type */
    VALUE name;	         /* String: iseq name */
    VALUE filename;      /* file information where this sequence from */
    VALUE *iseq;         /* iseq (insn number and openrads) */
    VALUE *iseq_encoded; /* encoded iseq */
    unsigned long iseq_size;
    VALUE mark_ary;	/* Array: includes operands which should be GC marked */
    VALUE coverage;     /* coverage array */

    /* insn info, must be freed */
    struct iseq_insn_info_entry *insn_info_table;
    unsigned long insn_info_size;

    ID *local_table;		/* must free */
    int local_table_size;

    /* method, class frame: sizeof(vars) + 1, block frame: sizeof(vars) */
    int local_size; 

    /**
     * argument information
     *
     *  def m(a1, a2, ..., aM,                    # mandatory
     *        b1=(...), b2=(...), ..., bN=(...),  # optinal
     *        *c,                                 # rest
     *        d1, d2, ..., dO,                    # post
     *        &e)                                 # block
     * =>
     *
     *  argc           = M
     *  arg_rest       = M+N+1 // or -1 if no rest arg
     *  arg_opts       = N
     *  arg_opts_tbl   = [ (N entries) ]
     *  arg_post_len   = O // 0 if no post arguments
     *  arg_post_start = M+N+2
     *  arg_block      = M+N + 1 + O + 1 // -1 if no block arg
     *  arg_simple     = 0 if not simple arguments.
     *                 = 1 if no opt, rest, post, block.
     *                 = 2 if ambiguos block parameter ({|a|}).
     *  arg_size       = argument size.
     */

    int argc;
    int arg_simple;
    int arg_rest;
    int arg_block;
    int arg_opts;
    int arg_post_len;
    int arg_post_start;
    int arg_size;
    VALUE *arg_opt_table;

    int stack_max; /* for stack overflow check */

    /* catch table */
    struct iseq_catch_table_entry *catch_table;
    int catch_table_size;

    /* for child iseq */
    struct rb_iseq_struct *parent_iseq;
    struct rb_iseq_struct *local_iseq;

    /****************/
    /* dynamic data */
    /****************/

    VALUE self;
    VALUE orig;			/* non-NULL if its data have origin */

    /* block inlining */
    /* 
     * NODE *node;
     * void *special_block_builder;
     * void *cached_special_block_builder;
     * VALUE cached_special_block;
     */

    /* klass/module nest information stack (cref) */
    NODE *cref_stack;
    VALUE klass;

    /* misc */
    ID defined_method_id;	/* for define_method */
    rb_iseq_profile_t profile;

    /* used at compile time */
    struct iseq_compile_data *compile_data;
};

// vm_core.h:298
typedef struct rb_vm_struct rb_vm_t; // mvm.h:15
struct rb_vm_struct
{
    VALUE self;

    rb_thread_lock_t global_vm_lock;

    struct rb_thread_struct *main_thread;
    struct rb_thread_struct *running_thread;

    st_table *living_threads;
    VALUE thgroup_default;

    int running;
    int thread_abort_on_exception;
    unsigned long trace_flag;
    volatile int sleeper;

    /* object management */
    VALUE mark_object_ary;

    VALUE special_exceptions[ruby_special_error_count];

    /* load */
    VALUE top_self;
    VALUE load_path;
    VALUE loaded_features;
    struct st_table *loading_table;
    
    /* signal */
    rb_atomic_t signal_buff[RUBY_NSIG];
    rb_atomic_t buffered_signal_size;

    /* hook */
    rb_event_hook_t *event_hooks;

    int src_encoding_index;

    VALUE verbose, debug, progname;
    VALUE coverages;

#if defined(ENABLE_VM_OBJSPACE) && ENABLE_VM_OBJSPACE
    struct rb_objspace *objspace;
#endif
};

// vm_core.h:402
typedef struct rb_thread_struct rb_thread_t; // mvm.h:16
struct rb_thread_struct
{
    VALUE self;
    rb_vm_t *vm;

    /* execution information */
    VALUE *stack;		/* must free, must mark */
    unsigned long stack_size;
    rb_control_frame_t *cfp;
    int safe_level;
    int raised_flag;
    VALUE last_status; /* $? */
    
    /* passing state */
    int state;

    /* for rb_iterate */
    rb_block_t *passed_block;

    /* for load(true) */
    VALUE top_self;
    VALUE top_wrapper;

    /* eval env */
    rb_block_t *base_block;

    VALUE *local_lfp;
    VALUE local_svar;

    /* thread control */
    rb_thread_id_t thread_id;
    enum rb_thread_status status;
    int priority;
    int slice;

    native_thread_data_t native_thread_data;

    VALUE thgroup;
    VALUE value;

    VALUE errinfo;
    VALUE thrown_errinfo;
    int exec_signal;

    int interrupt_flag;
    rb_thread_lock_t interrupt_lock;
    struct rb_unblock_callback unblock;
    VALUE locking_mutex;
    struct rb_mutex_struct *keeping_mutexes;
    int transition_for_lock;

    struct rb_vm_tag *tag;
    struct rb_vm_trap_tag *trap_tag;

    int parse_in_eval;
    int mild_compile_error;

    /* storage */
    st_table *local_storage;
#if USE_VALUE_CACHE
    VALUE value_cache[RUBY_VM_VALUE_CACHE_SIZE + 1];
    VALUE *value_cache_ptr;
#endif

    struct rb_thread_struct *join_list_next;
    struct rb_thread_struct *join_list_head;

    VALUE first_proc;
    VALUE first_args;
    VALUE (*first_func)(ANYARGS);

    /* for GC */
    VALUE *machine_stack_start;
    VALUE *machine_stack_end;
    size_t machine_stack_maxsize;
#ifdef __ia64
    VALUE *machine_register_stack_start;
    VALUE *machine_register_stack_end;
    size_t machine_register_stack_maxsize;
#endif
    jmp_buf machine_regs;
    int mark_stack_len;

    /* statistics data for profiler */
    VALUE stat_insn_usage;

    /* tracer */
    rb_event_hook_t *event_hooks;
    rb_event_flag_t event_flags;
    int tracing;

    /* fiber */
    VALUE fiber;
    VALUE root_fiber;
    rb_jmpbuf_t root_jmpbuf;

    /* misc */
    int method_missing_reason;
    int abort_on_exception;
};

