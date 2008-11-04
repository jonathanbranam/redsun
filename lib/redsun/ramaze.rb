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
    bc = load_file(filename)
    RedSun::ABC::ABCFile.yarv_to_string(bc)
  end

  def compile
    #puts "request #{ request.POST() }"
    bytecode = request.POST()["bytecode"].tr("\r","\n")
    bc = load_string(bytecode)
    RedSun::ABC::ABCFile.yarv_to_string(bc)
  end

  def load_string(string, required=[])
    bc = RubyVM::InstructionSequence.compile(string).to_a
    bc = process_bytecode(bc, required)
  end

  def load_file(filename, required=[])
    load_string(IO.read(filename), required)
  end

  def process_bytecode(bytecode, required=[])
    i = 0
    while true
      insn = bytecode[11][i]
      if insn.is_a? Array and insn[0] == :send and insn[1] == :require
        putnil = bytecode[11][i-2]
        if putnil.is_a? Array and putnil[0] == :putnil
          putstring = bytecode[11][i-1]
          if putstring.is_a? Array and putstring[0] == :putstring
            filename = putstring[1]
            unless required.include? filename
              prev_i = i - 3
              next_i = i + 1
              required << filename
              new_bc = load_file(filename, required)[11]
              i += new_bc.length-1
              # This doesn't seem very efficient...
              bytecode[11] = bytecode[11][0..prev_i]+
                new_bc[0..-2]+
                bytecode[11][next_i..-1]
            else
              bytecode[11].slice!(i-2,4)
              i -= 1
            end
          end
        end
      end
      i += 1
      break if i >= bytecode[11].length
    end
    bytecode
  end

end

Ramaze.start :adapter => :webrick

