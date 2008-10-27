module B
  def col
    0x66AA33
  end
end
class A
  def a
    yield
  end
end
a = A.new
a.extend B
a.a do
  Document.graphics.lineStyle(1,1,1)
  Document.graphics.beginFill(0x33AAEE)
  Document.graphics.drawRect(5,5,105,105)
end
=begin
module Draggable
  on :mouse_down do
    @dragging = true
    on :mouse_move do
      @x = e.x
      @y = e.y
    end
  end
end
module Selectable; end
module Resizable; end
module Rotateable; end



class Square
  include Draggable, Selectable, Resizable, Rotateable
end

class Circle
  include Selectable
end

module Bindable
  def self.attr_bindable(*sym)
    self.define_method do
    end
  end
end

class Whatever
  include Bindable
  attr_accessor :x, :y
  attr_bindable :width, :height
end




#puts "FAIL" unless v
#puts "SUCCESS" if v
# = begin
def a(); end
def b(a); end
def c(a,b); end
def d(a,b,*c); end 
def e(a,b,c=nil); end
def f(a,b,c=nil,d=nil); end
def g(a,b,*c,d); end
def h(a,b,&c); end
def i(a,b=nil,*c,d); end
def j(a,b,c=nil,*d,e,f,&g); end
=end
=begin
v = nil
puts "FAIL" if v

puts("hi")
class A
  def m
    "hi"
  end
  def dumb_string
    m=="hi"
  end
end
a = A.new
puts a.m
def test res
  puts "FAIL!" if not desc
end
test a.dumb_string
 = begin
class A
  class B < A
  end
  module C
  end
  class << self
  end
end
class T
  def parm_pos(p1, p2)
    i = p1
    i2 = p2
    puts i+i2
    puts p1+p2
  end
  def blarg
  end
  def blah(parm1)
    i = ' '+parm1
    i2 = 'there'
    ar = Array.new
    ar << 'hi'
    ar.each do |p1|
      puts "hi"+p1
    end
    ar.each do |hi|
      puts hi+i+i2
    end
    ar.each do
      puts "hi"
    end
  end
end

=end
