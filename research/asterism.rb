module Drawable
  attr_accessor :style
  def draw(sprite)
    sprite = sprite.do if sprite.respond_to? :do
    @style.begin_style(sprite) if @style
    draw_commands(sprite)
    @style.end_style(sprite) if @style
  end
end

class Line
  attr_accessor :x, :y, :x2, :y2
  include Drawable
  def draw_commands(sprite)
    sprite.graphics.move_to(@x,@y)
    sprite.graphics.line_to(@x2,@y2)
  end
end

class Rectangle
  attr_accessor :x, :y, :width, :height
  include Drawable
  def draw_commands(sprite)
    sprite.graphics.move_to(@x,@y)
    sprite.graphics.line_to(@x+@width,@y)
    sprite.graphics.line_to(@x+@width,@y+@height)
    sprite.graphics.line_to(@x,@y+@height)
    sprite.graphics.line_to(@x,@y)
  end
end

class Circle
  attr_accessor :x, :y, :radius
  include Drawable
  def diameter=(v)
    @radius = v/2
  end
  def draw_commands(sprite)
    sprite.graphics.draw_circle(@x, @y, @radius)
  end
end

module Geometry
  def line(props)
    l = Line.new
    l.x = props[:x]
    l.y = props[:y]
    l.x2 = props[:x2]
    l.y2 = props[:y2]
    l.style = props[:style]
    l
  end
  def rectangle(props)
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

module Style
  attr_accessor :line_thickness, :line_color, :line_alpha
  attr_accessor :fill, :fill_color, :fill_alpha
  def initialize
    @fill_alpha = 1
  end
  def begin_style(sprite)
    sprite.graphics.line_style(@line_thickness, @line_color, @line_alpha)
    sprite.graphics.begin_fill(@fill_color, @fill_alpha) if @fill
  end
  def end_style(sprite)
    sprite.graphics.end_fill() if @fill
  end
  def clone
    ns = self.class.new
    ns.line_thickness = @line_thickness
    ns.line_color = @line_color
    ns.line_alpha = @line_alpha
    ns.fill = @fill
    ns.fill_color = @fill_color
    ns.fill_alpha = @fill_alpha
    ns
  end
end

class DrawStyle
  include Style
end

=begin
geometry {
  square {:x =>5, :y =>5, :width =>100, :height =>10 }
  circle {}
}

geometry {
  circle - square
}

=end
