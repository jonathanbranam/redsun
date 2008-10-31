
module Drawer
  def draw
    super
    TopSprite.graphics.lineStyle(1,1,1)
    TopSprite.graphics.beginFill(0x228833)
    TopSprite.graphics.drawRect(5,5,105,105)
  end
end

class MyObj
  def draw
    puts "draw"
  end
  include Drawer
end

mo = MyObj.new

def mo.draw()
  super
  puts "draw"

end

mo.draw()

