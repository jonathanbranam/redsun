/*
The defines in Ruby source such as PUSH_TAG and POP_TAG relate to handling
exceptions in the Ruby code. These define a new C block context and save
the previous context in the tag member of the thread structure.

In C this code calls setjmp() and JUMP_TAG calls longjmp(). There are various
types of "tags" besides exceptions such as TAG_RETURN, TAG_BREAK, and TAG_REDO.
My current understanding is that these "tags" are the manner in which Ruby
implements its block control structures, particularly for Ruby blocks which
may be passed to methods.

For example, the code:
array.each do |e|
  next if e == "b"
  puts(e)
end

Results in bytecode with definitions for the span of which the :next
command will jump to a different location, as well as :break and :redo.

*/


