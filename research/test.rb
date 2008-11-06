
class A
  attr_accessor :width
  def width=(w)
    @width = w
  end
end

class B < A
  attr_accessor :my_width
  def width=(w)
    @my_width = w
    super w
  end
end

b = B.new

b.width = 50
