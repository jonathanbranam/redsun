require "research/asterism.rb"
require "research/ui_fmwk.rb"
require "research/slideshow.rb"

# puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.main_screen
#puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.native_window.x = ms.bounds.x
AIRWindow.native_window.y = ms.bounds.y
AIRWindow.native_window.width = 300 || ms.bounds.width
AIRWindow.native_window.height = 300 || ms.bounds.height

include Geometry

top = Mx::Core::UIComponent.new
TopSprite.add_child(top)

show = SlideShow.new(top)

Red=DrawStyle.new
Red.line_thickness = 2
Red.line_color = 0xFFFFFF
Red.line_alpha = 1
Red.fill = true
Red.fill_color = 0xDD6644
Blue = Red.clone
Blue.fill_color = 0x4466FF
Blue.fill_alpha = 1

show.new_slide do |slide|
  left, right = slide.split_horizontal 30
  left.render do |s|
    rectangle({:x=>0, :y=>80, :width=>60,
                :height=>20, :style=>Red }).draw(s)
    circle({:x=>150, :y=>80, 
             :radius=>60, :style=>Blue }).draw(s)
  end
  right.ruby_code =<<HERE
show.new_slide do |slide|
  left, right = slide.split_horizontal 30
  left.render do |s|
    rectangle({:x=>0, :y=>80, :width=>60,
                :height=>20, :style=>Red }).draw(s)
    circle({:x=>150, :y=>80, 
             :radius=>60, :style=>Blue }).draw(s)
  end
  right.html_text = 'Infinite recursion'
end
HERE
end

show.start

