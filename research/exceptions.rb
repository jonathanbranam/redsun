
# Testing exceptions
puts "Before Raise"
begin
  raise "Something"
  puts "Not Rescued"
rescue 
  puts "Rescued"
end

begin
  "corey".i_do_not_exist
rescue NoMethodError
  puts "wrong place"
rescue 
  puts "right place"
end

class A
  def b
    puts "raise from b"
    raise "from b"
  end
end

a = A.new
begin
  puts "rescue from a.b"
  a.b
  puts "should not execute"
rescue
  puts "Should rescue"
end
