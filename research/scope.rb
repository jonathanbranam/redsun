a = [1,1,1]
@color = 0xDD6622
TopSprite.graphics.lineStyle(a[0], a[1], a[2])
TopSprite.graphics.beginFill(@color)

p = {:x =>5, :y =>5, :width =>20, :height =>100}
TopSprite.graphics.drawRect(p[:x], p[:y], p[:width], p[:height])

class Text
  attr_accessor :tf
  def initialize
    @tf = Flash::Text::TextField.new
    @tf.text = "Hello!"
    @tf.x = 250
    @tf.y = 50
    @tf.selectable = false
    tfor = Flash::Text::TextFormat.new
    tfor.size = 25
    @tf.setTextFormat(tfor)
    TopSprite.addChild(@tf)
  end
  def x
    @tf.x
  end
  def x= val
    @tf.x = val
  end
  class << self
    def new_blah
      t = Text.new
      t.tf.text = "BLAH"
      t
    end
  end
end

t = Text.new_blah

def t.name(s)
  @tf.text = s
end

t.name("bloooy")

wait(1)
t.tf.x -= 50
#t.x = t.x- 50
wait(1)
t.tf.x -= 50
#t.x = t.x- 50
wait(1)
t.tf.x -= 50
#t.x = t.x- 50
wait(1)
t.tf.x -= 50
#t.x -= 50
wait(1)
t.tf.x -= 50
#t.x -= 50
wait(1)
t.tf.x -= 50
#t.x -= 50
wait(1)
t.tf.x -= 50
#t.x -= 50

=begin

@blah = "hi"

def talk_to_server(blah)
  http = HTTPService.new
  http.url = "junk"
  http.send
  wait_for(http, :result)
  result = http.result
  parse(result)
  yield result
end

th = Thread.new(&talk_to_server) do |result|
 tf.text = result
end


next_frame()

for_seconds(1.seconds) do 
  tf.alpha += 0.1
end

fadein = Tween.new(0,1) do |obj, val|
  obj.alpha = val
end

fadein.run(tf)


module Sketch
  def geometry &m
    instance_eval m
  end
  def circle(op)
  end
  def draw(s)
  end
end
class Drawy
  include Sketch
  def a
    skin = geometry {
      circle {:x=>40,:y=>40,:radius=>20}
    }
    skin.draw(s)
  end
end
module B
  def col
    0x66AA33
  end
end
class A
  def a
    sp = Flash::Display::Sprite.new
    yield sp
  end
end
a = A.new
a.extend B
a.a do |s|
  Document.addChild(s)
  s.graphics.lineStyle(1,1,1)
  s.graphics.beginFill(0x33AAEE)
  s.graphics.drawRect(5,5,105,105)
end
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
  attr_commit :prop
  attr_commit_my_method :prop, :prop_my_commit_method
  attr_commit_order :prop, 2
  attr_commit_order :prop2, 4
  def prop_commit(old, new)
    # Do really long thing
  end
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
