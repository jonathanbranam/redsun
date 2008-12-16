
# Testing exceptions
puts "start"
begin
  raise StandardError, "with description"
  puts "** didn't raise"
rescue NoMethodError
  puts "** caught NoMethodError"
rescue RuntimeError
  puts "** caught RuntimeError"
rescue StandardError => bob
  puts "caught StandardError: "+bob.to_s
end

begin
  raise "runtime error"
  puts "** didn't raise"
rescue NoMethodError
  puts "** caught NoMethodError"
rescue
  puts "caught any error"
end

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
  puts "right place"
rescue 
  puts "wrong place"
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

