require 'rubygems'
require 'ramaze'
require 'redsun'

class MainController < Ramaze::Controller
  def index
    'Hello, world!'
  end

  def compile_file(*filename)
    filename = filename.join("/")
    return "\"file name error\"" if filename.include? ".."
    return "\"file name error\"" if filename.start_with? "/"
    return "\"file name error\"" if filename.start_with? "\\"
    bc = RubyVM::InstructionSequence.compile(IO.read(filename)).to_a
    RedSun::ABC::ABCFile.yarv_to_string(bc)
  end

  def compile
    puts "request #{ request.POST() }"
    bytecode = request.POST()["bytecode"].tr("\r","\n")
    bc = RubyVM::InstructionSequence.compile(bytecode).to_a
    RedSun::ABC::ABCFile.yarv_to_string(bc)
  end
    

end

Ramaze.start :adapter => :webrick

