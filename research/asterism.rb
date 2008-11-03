
class Rectangle
  attr_accessor :x, :y, :width, :height, :style
  def draw(sprite)
    @style.begin_style(sprite) if @style
    sprite.graphics.drawRect(@x, @y, @width, @height)
    @style.end_style(sprite) if @style
  end
end

class Circle
  attr_accessor :x, :y, :radius, :style
  def diameter=(v)
    @radius = v/2
  end
  def draw(sprite)
    @style.begin_style(sprite) if @style
    sprite.graphics.drawCircle(@x, @y, @radius)
    @style.end_style(sprite) if @style
  end
end

module Geometry
  def rectangle props
    r = Rectangle.new
    r.x = props[:x] || 0
    r.y = props[:y] || 0
    r.width = props[:width] || 10
    r.height = props[:height] || 10
    r.style = props[:style]
    r
  end
  def circle(props)
    c = Circle.new
    c.x = props[:x] || 0
    c.y = props[:y] || 0
    if props[:radius]
      c.radius = props[:radius]
    elsif props[:diameter]
      c.diameter = props[:diameter]
    else
      c.radius = 10
    end
    c.style = props[:style]
    c
  end
end

class DrawStyle
  attr_accessor :line_thickness, :line_color, :line_alpha
  attr_accessor :fill, :fill_color
  def begin_style(sprite)
    sprite.graphics.lineStyle(@line_thickness, @line_color, @line_alpha)
    sprite.graphics.beginFill(@fill_color) if @fill
  end
  def end_style(sprite)
    sprite.graphics.endFill() if @fill
  end
  def clone
    ns = self.class.new
    ns.line_thickness = @line_thickness
    ns.line_color = @line_color
    ns.line_alpha = @line_alpha
    ns.fill = @fill
    ns.fill_color = @fill_color
    ns
  end
end

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
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(TopSprite)

=begin
geometry {
  square {:x =>5, :y =>5, :width =>100, :height =>10 }
  circle {}
}

geometry {
  cricle - square
}

=end
