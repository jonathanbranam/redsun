
class A
  attr_accessor :width
  def width=(w)
    @width = w
  end
end

class B < A
  attr_accessor :my_width
  alias_method :super_w=, :width=
  def width=(w)
    @my_width = w+30
    self.super_w=(w)
  end
end

b = B.new

b.width = 50

puts "should be 80: #{b.my_width}, should be 50: #{b.width}"
