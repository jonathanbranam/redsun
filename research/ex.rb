#!/usr/bin/ruby

require 'redsun'

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
@s = RedSun::Swf.new "test/files/EmptySwf.swf"
@md = RedSun::Swf.new "test/files/MethodDecompile.swf"
@sc = RedSun::Swf.new "test/files/SeveralClasses.swf"
@t = RedSun::Swf.new "test/files/Traits.swf"
# @t.tags[8].abc_file.instances[0].iinit.body.code.pretty_print;nil

@af = RedSun::ABC::ABCFile.new
@e_vm=VM::InstructionSequence.compile(IO.read('test/files/empty.rb')).to_a
@af.load_ruby(@e_vm)

@ss = RedSun::Swf.new
@ss.create_stub_swf("EmptySwf")

@bs = RedSun::Swf.new
@bs.create_stub_swf("Basic", IO.read('test/files/basic.rb'))

@ts = RedSun::Swf.new
@ts.create_stub_swf("Traits", IO.read('test/files/traits.rb'))
@ts.filename = 'traits'
# @ts.write

@bvm=VM::InstructionSequence.compile(IO.read('test/files/basic.rb')).to_a
# RedSun::ABC::ABCFile.pp_yarv(@bvm)

@tvm=VM::InstructionSequence.compile(IO.read('test/files/traits.rb')).to_a
# RedSun::ABC::ABCFile.pp_yarv(@tvm)


