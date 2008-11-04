=begin
def callback(e, p)
  p.call e
end

callback("hello from proc", Proc.new do |e|
  puts e
end)
=end

on :keyDown do |e|
  puts "keyDown: #{e.keyCode}."
end

on :keyDown { |e| puts "key down, code #{e.keyCode}" }
