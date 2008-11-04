require 'research/asterism.rb'

include Geometry

red=DrawStyle.new
red.line_thickness = 5
red.line_color = 0
red.line_alpha = 1
red.fill = true
red.fill_color = 0xFF5522
rectangle({:x=>43, :y=>16, :width=>100, :height=>20, :style=>red}).draw(TopSprite)
blue = red.clone
blue.fill_color = 0x2255FF
blue.fill_alpha = 0.2
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(TopSprite)
