require "research/asterism.rb"

#require "research/asterism_demo.rb"

puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.main_screen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.native_window.x = ms.bounds.x
AIRWindow.native_window.y = ms.bounds.y
AIRWindow.native_window.width = 300 || ms.bounds.width
AIRWindow.native_window.height = 300 || ms.bounds.height


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
    props.each do |o|
      o.commit_properties() if o.respond_to? :commit_properties
    end
    size = @size
    @size = []
    size.each do |o|
      o.measure() if o.respond_to? :measure
    end
    display = @display
    @display = []
    display.each do |o|
      puts "Updating display for #{o}."
      o.update_display() if o.respond_to? :update_display
    end
  end
  def self.invalidate_properties(o)
    @@vm.props << o
  end
  def self.invalidate_size(o)
    @@vm.size << o
  end
  def self.invalidate_display(o)
    @@vm.display << o
  end
end

@vm = ValidationManager.new

module PropValidator
  def invalidate_properties()
    ValidationManager.invalidate_properties(self)
  end
  def commit_properties()
  end
end

module SizeInvalidation
  def invalidate_size()
    ValidationManager.invalidate_size(self)
  end
  def width=(w)
    super
    invalidate_size()
  end
  def height=(h)
    super
    invalidate_size()
  end
  def measure()
  end
end

module DisplayInvalidation
  def invalidate_display()
    ValidationManager.invalidate_display(self)
  end
  def invalidate_size()
    super
    invalidate_display()
  end
  def update_display()
  end
end

class SlideShow
  attr_accessor :frame, :slides, :index, :end
  def initialize(parent)
    @frame = Flash::Display::Sprite.new
    parent.add_child(@frame)
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
  def first_slide
    @index = -1
    next_slide
  end
  def last_slide
    @index = @slides.length
    next_slide
  end
  def next_slide
    @frame.remove_child(@cur_frame) if @cur_frame
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
    @frame.add_child(@cur_frame)
  end
  def prev_slide
    @frame.remove_child(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index - 1 if @index > 0
    return if @index >= @slides.length
    return if @index < 0
    @cur_frame = Flash::Display::Sprite.new
    sl = @slides[@index]
    sl.parent = @cur_frame
    @frame.add_child(@cur_frame)
  end
end
    

class Slide
  attr_accessor :layout, :children, :sprite
  include PropValidator
  def parent=(v)
    v.add_child(sprite)
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
scale = AIRWindow.native_window.width/200.1/2
TopSprite.add_child(top)
top.scaleX = top.scaleY = scale

AIRWindow.on :windowResize do |e|
  scale = e.after_bounds.width/200.1/2
  #puts "#{e.after_bounds.width} x #{e.after_bounds.height} scale: #{scale}" 
  top.scaleX = top.scaleY = scale
end

sl1 = Slide.new
sl1.invalidate_properties()

sl2 = Slide.new


show = SlideShow.new(top)
show.add(sl1)
show.add(sl2)

#sp = Flash::Display::Sprite.new
#sl1.add_child(sp)

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
  def self.included(k)
    k.alias_method :super_width=, :width=
    k.alias_method :super_height=, :height=
  end
  def set_size(width, height)
    self.super_width = width
    self.super_height = height
  end
  def width=(width)
    super
    @explicit_width = width
  end
end

module DisplayObjectPassthrough
  def parent=(v)  v.add_child(@do); end
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

module SizeBlock
  def width=(w)   @width = w;      end
  def width()     @width;          end
  def height=(h)  @height = h;     end
  def height()    @height;         end
end

class Text
  attr_accessor :text_field
  include DisplayObjectPassthrough
  include PercentLayout
  def initialize
    @text_field = Flash::Text::TextField.new
    @do = @text_field
    @text_field.selectable = false
  end
end

tf = Text.new
tf.x = 200
tf.y = 0
tf.width = 200
tf.height = 400
sl1.sprite.add_child(tf.text_field)
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
    percent_scale = total_percent/100.00001
    remaining_width = width
    percent_width = width - total_width
    puts "HBox pscale #{percent_scale}"
    # use up explicit space first
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      if not pw
        o.set_size(w, o.height)
        remaining_width -= w
      end
    end
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      if pw
        o.set_size(pw*percent_scale/100.00001*remaining_width, o.height)
      end
    end
  end
end

class Canvas
  attr_accessor :sprite
  include DisplayObjectPassthrough
  include SizeBlock
  include PercentLayout
  include SizeInvalidation
  include DisplayInvalidation
  def initialize
    @sprite = Flash::Display::Sprite.new
    @do = @sprite
  end
end

show.new_slide do |slide|
  l = HBox.new
  left = Canvas.new
  left.percent_width = 50
  def left.update_display
    puts "Updating left display"
    red=DrawStyle.new
    red.line_thickness = 2
    red.line_color = 0
    red.line_alpha = 1
    red.fill = true
    red.fill_color = 0xFF5522
    circle({:x=>50, :y=>80, :radius =>50, :style=>red }).draw(@sprite)
  end
  left.invalidate_display
  #left.width = 100

  right = Text.new
  right.text = "Test Text"
  right.x = 100
  #right.width = 100
  right.percent_width = 50

  slide.sprite.add_child(left.sprite)
  slide.sprite.add_child(right.text_field)
  l.layout([left,right], 200)
  #slide.draw(circle ({:x=>150, :y=>180, :radius =>80, :style=>blue }))
  #c.draw(slide.sprite)
end

etf = Text.new
etf.text = "END"
show.end.sprite.add_child(etf.text_field)

show.start

@was_fullscreen = false
def toggle_fullscreen
  if (TopSprite.stage.display_state == "fullScreen" or
      TopSprite.stage.display_state == "fullScreenInteractive") then
    @was_fullscreen = false
    TopSprite.stage.display_state = "normal"
  else
    @was_fullscreen = true
    TopSprite.stage.display_state = "fullScreenInteractive"
  end
end

def exit_fullscreen_or_close
  # stage.display_state has already changed before :key_down of ESC
  AIRWindow.close if not @was_fullscreen
  @was_fullscreen = false
end

on :key_down do |e|
  puts "key code #{e.key_code}"
  done = false
  if e.key_code == 37 and e.command_key
    show.first_slide
    done = true
  end
  if not done
    if e.key_code == 39 and e.command_key
      show.last_slide
      done = true
    end
  end
  if not done
    show.next_slide if e.key_code == 39 or e.key_code == 13 or e.key_code == 32
    show.prev_slide if e.key_code == 37
    exit_fullscreen_or_close if e.key_code == 27
    toggle_fullscreen if e.key_code == 70
  end
end

AIRWindow.on :window_activate do |e|
  TopSprite.set_focus()
end

TopSprite.set_focus()
