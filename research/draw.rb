a = [1,1,1]
TopSprite.graphics.line_style(a[0], a[1], a[2])
TopSprite.graphics.begin_fill(0x33AAEE)
TopSprite.graphics.draw_rect(5,5,105,105)

=begin

module Sketch
  def geometry &m
    instance_eval m
  end
  def circle(op)
  end
  def draw(s)
  end
end
class Drawy
  include Sketch
  def a
    skin = geometry {
      circle {:x=>40,:y=>40,:radius=>20}
    }
    skin.draw(s)
  end
end
module B
  def col
    0x66AA33
  end
end
class A
  def a
    sp = Flash::Display::Sprite.new
    yield sp
  end
end

=end
