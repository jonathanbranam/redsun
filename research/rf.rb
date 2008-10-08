class RFMain < Sprite
	def initialize
		super
		graphics.lineStyle(1,1,1)
		graphics.beginFill(0xFF0000, 1)
		graphics.moveTo(0,0)
		graphics.drawRect(0,0, 100,100)
	end

	def method1(p1, p2=nil)
		super
		@field1 = p1
		@field2 = p2 if p2
		method2(p1) do |i|
			puts "hello #{i}"
		end
	end

	def method2(p1)
		1.upto(p1) { |i|
			yield i
		}
	end

end

