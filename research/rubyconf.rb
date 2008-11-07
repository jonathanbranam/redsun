require "research/asterism.rb"
require "research/ui_fmwk.rb"
require "research/slideshow.rb"

puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.main_screen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.native_window.x = ms.bounds.x
AIRWindow.native_window.y = ms.bounds.y
AIRWindow.native_window.width = 300 || ms.bounds.width
AIRWindow.native_window.height = 300 || ms.bounds.height

TopSprite.graphics.begin_fill(0x111111)
TopSprite.graphics.draw_rect(0,0,10000,10000)
TopSprite.graphics.end_fill()
TopSprite.graphics.begin_fill(0xFFFFFF,0)

include Geometry

top = Mx::Core::UIComponent.new
TopSprite.add_child(top)

sl1 = Slide.new
sl1.invalidate_properties()

sl2 = Slide.new


show = SlideShow.new(top)
show.add(sl1)
show.add(sl2)

sp = sl1.sprite
red=DrawStyle.new
red.line_thickness = 2
red.line_color = 0xFFFFFF
red.line_alpha = 1
red.fill = true
red.fill_color = 0xFF5522
rectangle({:x=>11, :y=>16, 
            :width=>100, :height=>20, 
            :style=>red}).draw(sl1.sprite)
blue = red.clone
blue.fill_color = 0x2255FF
blue.fill_alpha = 0.2
Blue = blue
Red = red
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sl1.sprite)

cl = true
on :enterFrame do |e|
  sp.x = sp.x-1 if cl
  sp.x = sp.x+1 if not cl
  cl = true if sp.x > 50
  cl = false if sp.x <= 0
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

show.new_slide do |slide|
  left, right = slide.split_horizontal
  left.render do |s|
    circle ({:x=>50, :y=>80, :radius =>30, :style=>Blue }).draw(s)
  end
  right.text =<<HERE
def Circle
  def draw()
    puts 'draw'
  end
end
HERE
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

show.start

