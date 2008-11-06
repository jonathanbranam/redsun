require "research/asterism.rb"

#require "research/asterism_demo.rb"

puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.mainScreen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.nativeWindow.x = ms.bounds.x
AIRWindow.nativeWindow.y = ms.bounds.y
AIRWindow.nativeWindow.width = 300 || ms.bounds.width
AIRWindow.nativeWindow.height = 300 || ms.bounds.height


include Geometry

class ValidationManager
  attr_accessor :props, :size, :display
  def initialize
    @@vm = self
    @props = []
    @size = []
    @display = []
    vm = self
    TopSprite.on :enterFrame { |e| vm.validate }
  end
  def validate()
    props = @props
    @props = []
    #puts "validate #{props.length} objects"
    props.each do |o|
      o.commitProperties()
    end
  end
  def self.invalidateProperties(o)
    @@vm.props << o
  end
  def self.invalidateSize(o)
    @@vm.size << o
  end
  def self.invalidateDisplay(o)
    @@vm.display << o
  end
end

@vm = ValidationManager.new

module PropValidator
  def invalidateProperties()
    ValidationManager.invalidateProperties(self)
  end
  def commitProperties()
  end
end

class SlideShow
  attr_accessor :frame, :slides, :index
  def initialize(parent)
    @frame = Flash::Display::Sprite.new
    parent.addChild(@frame)
    @slides = []
    @cur_frame = nil
  end
  def add(sl)
    @slides << sl
  end
  def start
    @index = -1
    next_slide
  end
  def next_slide
    @frame.removeChild(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index + 1 if @index <= @slides.length
    return if @index >= @slides.length
    @cur_frame = Flash::Display::Sprite.new
    sl = @slides[@index]
    sl.parent = @cur_frame
    @frame.addChild(@cur_frame)
  end
  def prev_slide
    @frame.removeChild(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index - 1 if @index > 0
    return if @index >= @slides.length
    return if @index < 0
    @cur_frame = Flash::Display::Sprite.new
    sl = @slides[@index]
    sl.parent = @cur_frame
    @frame.addChild(@cur_frame)
  end
end
    

class Slide
  attr_accessor :layout, :children, :sprite
  include PropValidator
  def parent=(v)
    v.addChild(sprite)
  end
  def initialize
    @sprite = Flash::Display::Sprite.new
  end
  def commitProperties()
  end
end


top = Flash::Display::Sprite.new
scale = AIRWindow.nativeWindow.width/200.1/2
TopSprite.addChild(top)
top.scaleX = top.scaleY = scale

AIRWindow.on :windowResize do |e|
  scale = e.afterBounds.width/200.1/2
  #puts "#{e.afterBounds.width} x #{e.afterBounds.height} scale: #{scale}" 
  top.scaleX = top.scaleY = scale
end

sl1 = Slide.new
sl1.invalidateProperties()

sl2 = Slide.new


show = SlideShow.new(top)
show.add(sl1)
show.add(sl2)

#sp = Flash::Display::Sprite.new
#sl1.addChild(sp)

sp = sl1.sprite
red=DrawStyle.new
red.line_thickness = 2
red.line_color = 0
red.line_alpha = 1
red.fill = true
red.fill_color = 0xFF5522
rectangle({:x=>11, :y=>16, :width=>100, :height=>20, :style=>red}).draw(sl1.sprite)
blue = red.clone
blue.fill_color = 0x2255FF
blue.fill_alpha = 0.2
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sl1.sprite)

cl = true
on :enterFrame do |e|
  sp.x = sp.x-1 if cl
  sp.x = sp.x+1 if not cl
  cl = true if sp.x > 50
  cl = false if sp.x <= 0
end



tf = Flash::Text::TextField.new
tf.x = 200
tf.y = 0
tf.width = 200
tf.height = 400
sl1.sprite.addChild(tf)
tf.text = "def Circle\n  def draw(sprite)\n  end\nend"

c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sl2.sprite)


show.start

on :keyDown do |e|
  puts "key code #{e.keyCode}"
  show.next_slide if e.keyCode == 39
  show.prev_slide if e.keyCode == 37
end

TopSprite.setFocus()
