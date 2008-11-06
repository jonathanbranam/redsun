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
  attr_accessor :frame, :slides, :index, :end
  def initialize(parent)
    @frame = Flash::Display::Sprite.new
    parent.addChild(@frame)
    @slides = []
    @cur_frame = nil
    @end = Slide.new
  end
  def add(sl)
    @slides << sl
  end
  def new_slide
    slide = Slide.new
    yield slide
    add(slide)
  end
  def start
    @index = -1
    next_slide
  end
  def next_slide
    @frame.removeChild(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index + 1 if @index < @slides.length
    @cur_frame = Flash::Display::Sprite.new
    if @index < @slides.length
      sl = @slides[@index]
      sl.parent = @cur_frame
    else
      sl = @end
      sl.parent = @cur_frame
    end
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
    @do = @sprite
  end
  def commitProperties()
  end
  def draw(obj)
    obj.draw(@sprite)
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
rectangle({:x=>11, :y=>16, 
            :width=>100, :height=>20, 
            :style=>red}).draw(sl1.sprite)
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

module PercentLayout
  attr_accessor :percent_width, :percent_height
  attr_accessor :explicit_width, :explicit_height
  def set_size(width, height)
    super.width = width
    super.height = height
  end
  def width=(width)
    @explicit_width = width
    #super.width = width
    #@do.width = width
    super
  end
end

module DisplayObjectPassthrough
  def parent=(v)  v.addChild(@do); end
  def parent()    @do.parent;      end
  def text=(v)    @do.text = v;    end
  def text()      @do.text;        end
  def x=(v)       @do.x = v;       end
  def x()         @do.x;           end
  def y=(v)       @do.y = v;       end
  def y()         @do.y;           end
  def width=(v)   @do.width = v;   end
  def width()     @do.width;       end
  def height=(v)  @do.height = v;  end
  def height()    @do.height;      end
end

class Text
  attr_accessor :text_field
  include DisplayObjectPassthrough
  include PercentLayout
  def initialize
    @text_field = Flash::Text::TextField.new
    @do = @text_field
  end
end

tf = Text.new
tf.x = 200
tf.y = 0
tf.width = 200
tf.height = 400
sl1.sprite.addChild(tf.text_field)
tf.text = "def Circle\n  def draw(sprite)\n  end\nend"

c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sl2.sprite)

class HBox
  def layout(objects, width)
    total_percent = 0
    total_width = 0
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      total_percent += pw if pw
      total_width += w if not pw and w
    end
=begin
    percent_scale = total_percent/100
    remaining_width = width
    percent_width = width - total_width
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      if pw
        o.set_size(pw*percent_scale, o.height)
      end
    end
=end
  end
end

class Canvas
  attr_accessor :sprite
  include DisplayObjectPassthrough
  include PercentLayout
  def initialize
    @sprite = Flash::Display::Sprite.new
    @do = @sprite
  end
end

show.new_slide do |slide|
  l = HBox.new
  left = Canvas.new
  #left.percent_width = 50
  circle({:x=>150, :y=>180, :radius =>80, :style=>blue }).draw(left.sprite)
  right = Text.new
  right.text = "Test Text"
  #right.percent_width = 50
  #l.layout([left,right], 200)
  #slide.draw(circle ({:x=>150, :y=>180, :radius =>80, :style=>blue }))
  #c.draw(slide.sprite)
end

etf = Text.new
etf.text = "END"
show.end.sprite.addChild(etf.text_field)

show.start

on :keyDown do |e|
  #puts "key code #{e.keyCode}"
  show.next_slide if e.keyCode == 39
  show.prev_slide if e.keyCode == 37
  AIRWindow.close if e.keyCode == 27
end

AIRWindow.on :windowActivate do |e|
  TopSprite.setFocus()
end

TopSprite.setFocus()
