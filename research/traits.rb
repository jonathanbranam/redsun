class Traits < Flash::Display::Sprite
	def initialize
		super
		draw(0x334400, 10, 20)
		draw(0x336655, 60, 20)
	end
	def draw(color, x, y)
		graphics.lineStyle(4, 0, 1)
		graphics.beginFill(color, 1)
		graphics.drawRoundRect(x, y, 40, 30, 5)
	end
end
