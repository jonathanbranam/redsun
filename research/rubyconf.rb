require "research/asterism.rb"

#require "research/asterism_demo.rb"

puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.mainScreen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.nativeWindow.x = ms.bounds.x
AIRWindow.nativeWindow.y = ms.bounds.y
AIRWindow.nativeWindow.width = ms.bounds.width
AIRWindow.nativeWindow.height = ms.bounds.height


include Geometry

top = Flash::Display::Sprite.new
scale = ms.bounds.width/200/2
TopSprite.addChild(top)
top.scaleX = top.scaleY = scale

sp = Flash::Display::Sprite.new
top.addChild(sp)

red=DrawStyle.new
red.line_thickness = 2
red.line_color = 0
red.line_alpha = 1
red.fill = true
red.fill_color = 0xFF5522
rectangle({:x=>11, :y=>16, :width=>100, :height=>20, :style=>red}).draw(sp)
blue = red.clone
blue.fill_color = 0x2255FF
blue.fill_alpha = 0.2
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sp)


tf = Flash::Text::TextField.new
tf.x = 200
tf.y = 0
tf.width = 200
tf.height = 400
top.addChild(tf)
tf.text = "def Circle\n  def draw(sprite)\n  end\nend"
