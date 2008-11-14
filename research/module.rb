
module Drawer
  def draw
    puts "Drawer#draw"
    TopSprite.graphics.line_style(1,1,1)
    TopSprite.graphics.begin_fill(0x228833)
    TopSprite.graphics.draw_rect(5,5,105,105)
  end
end

class MyClass
  def draw
    puts "MyClass#draw"
    super
  end
  include Drawer
end

mo = MyClass.new

def mo.draw()
  puts "mo#draw"
  super
end

mo.draw()
# will execute in this order:
# mo#draw
# MyClass#draw
# Drawer#draw

