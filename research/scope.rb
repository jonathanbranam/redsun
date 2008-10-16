class T
  def parm_pos(p1, p2)
    i = p1
    i2 = p2
    puts i+i2
    puts p1+p2
  end
  def blarg
  end
  def blah(parm1)
    i = ' '+parm1
    i2 = 'there'
    ar = Array.new
    ar << 'hi'
    ar.each do |p1|
      puts "hi"+p1
    end
    ar.each do |hi|
      puts hi+i+i2
    end
    ar.each do
      puts "hi"
    end
  end
end

