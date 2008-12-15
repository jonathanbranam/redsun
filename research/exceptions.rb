
# Testing exceptions
puts "Before Raise"
begin
  raise "Something"
  puts "Not Rescued"
rescue 
  puts "Rescued"
end

