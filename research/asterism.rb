
class Rectangle
  attr_accessor :x, :y, :width, :height
  def draw(sprite)
    sprite.drawRect(@x, @y, @width, @height)
  end
end

class Circle
  attr_accessor :x, :y, :radius
  def diameter=(v)
    @radius = v/2
  end
  def draw(sprite)
    sprite.drawCircle(@x, @y, @radius)
  end
end

module Geometry
  def rectangle props
    r = Rectangle.new
    r.x = props[:x] || 0
    r.y = props[:y] || 0
    r.width = props[:width] = 10
    r.height = props[:height] = 10
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
    c
  end
end

include Geometry

rectangle({:x=>13, :y=>16, :width=>100, :height=>20}).draw(TopSprite)
c = circle ({:radius =>30 })
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
