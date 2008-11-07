
Val1 = "val1"
Val2 = "val2"

class A
  attr_accessor :r
  def initialize
    @r = []
  end
  def boo(&r)
    @r << r
  end
end

def blah1
  a = A.new
  yield a
  a.r[0].call("hi")
  a.r[1].call("hi")
end

blah1 do |a|
  val1 = "val1"
  val2 = "val2"
  a.boo do |m|
    puts "msg: #{m}"
    puts "Val1: #{Val1} Val2: #{Val2}"
  end
  a.boo do |m2|
    puts "msg2: #{m2}"
    puts "Val1: #{Val1} Val2: #{Val2}"
  end
  puts "val1: #{val1} val2: #{val2}"
end
