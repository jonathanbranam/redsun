

./ruby -e 'puts VM::InstructionSequence.compile("proc {|x| x = 12 }.call(1)").disasm'

ruby -e 'puts VM::InstructionSequence.compile("def a(x) x = 12; end; a(1)").disasm'

