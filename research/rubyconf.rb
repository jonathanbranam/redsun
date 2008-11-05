require "research/asterism.rb"

#require "research/asterism_demo.rb"

puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.mainScreen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.nativeWindow.x = ms.bounds.x
AIRWindow.nativeWindow.y = ms.bounds.y
AIRWindow.nativeWindow.width = 300 || ms.bounds.width
AIRWindow.nativeWindow.height = 300 || ms.bounds.height


include Geometry

class ValidationManager
  attr_accessor :props, :size, :display
  def initialize
    @@vm = self
    @props = []
    @size = []
    @display = []
    vm = self
    TopSprite.on :enterFrame { |e| vm.validate }
  end
  def validate()
    props = @props
    @props = []
    puts "validate #{props.length} objects"
    props.each do |o|
      o.commitProperties()
    end
  end
  def self.invalidateProperties(o)
    @@vm.props << o
  end
  def self.invalidateSize(o)
    @@vm.size << o
  end
  def self.invalidateDisplay(o)
    @@vm.display << o
  end
end

@vm = ValidationManager.new

module PropValidator
  def invalidateProperties()
    ValidationManager.invalidateProperties(self)
  end
  def commitProperties()
  end
end


class Slide
  attr_accessor :parent, :layout, :children
  include PropValidator
  def initialize(parent)
    @parent = parent
  end
  def commitProperties()
  end
end


top = Flash::Display::Sprite.new
scale = ms.bounds.width/200/2
TopSprite.addChild(top)
top.scaleX = top.scaleY = scale

sl1 = Slide.new(top)
sl1.invalidateProperties()

sp = Flash::Display::Sprite.new
top.addChild(sp)

red=DrawStyle.new
red.line_thickness = 2
red.line_color = 0
red.line_alpha = 1
red.fill = true
red.fill_color = 0xFF5522
rectangle({:x=>11, :y=>16, :width=>100, :height=>20, :style=>red}).draw(sp)
blue = red.clone
blue.fill_color = 0x2255FF
blue.fill_alpha = 0.2
c = circle ({:x=>50, :y=>80, :radius =>30, :style=>blue })
c.draw(sp)


tf = Flash::Text::TextField.new
tf.x = 200
tf.y = 0
tf.width = 200
tf.height = 400
top.addChild(tf)
tf.text = "def Circle\n  def draw(sprite)\n  end\nend"
