
class Basic < Flash::Display::Sprite
  def initialize
    super
    sp = Flash::Display::Sprite.new
    sp.get.graphics.lineStyle(1,1,1)
    sp.get.graphics.beginFill(0x005500,1)
    sp.get.graphics.drawCircle(50,50,45)
    sp.get.graphics.endFill()
    addChild(sp)
  end
end

