#!/usr/bin/ruby

require 'swfr'

=begin
t = Test.new
p t.gds
puts
puts t.gds[0].fills
puts t.gds[0].commands

p ParseTree.translate(Test)

s = Swf.new "EmptySwf.swf"
p s.sig
p s.compressed
p s.version
p s.length
p s.frame_size
p s.frame_rate
p s.frame_count

#s.compressed = false
#s.write

c=VM::InstructionSequence.compile(IO.read('rf.rb'))

=end
@s = Swf.new "EmptySwf.swf"
@md = Swf.new "MethodDecompile.swf"
@sc = Swf.new "SeveralClasses.swf"
@t = Swf.new "Traits.swf"
# @t.tags[8].abc_file.instances[0].iinit.body.code.pretty_print;nil

@af = ABCFile.new
@e_vm=VM::InstructionSequence.compile(IO.read('empty.rb')).to_a
@af.load_ruby(@e_vm)

@ss = Swf.new
@ss.create_stub_swf("EmptySwf")

@bs = Swf.new
@bs.create_stub_swf("Basic", IO.read('basic.rb'))

@ts = Swf.new
@ts.create_stub_swf("Traits", IO.read('traits.rb'))
@ts.filename = 'traits'
# @ts.write

@bvm=VM::InstructionSequence.compile(IO.read('basic.rb')).to_a
# ABCFile.pp_yarv(@bvm)

@tvm=VM::InstructionSequence.compile(IO.read('traits.rb')).to_a
# ABCFile.pp_yarv(@tvm)

