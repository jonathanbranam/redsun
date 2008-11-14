=begin
def callback(e, p)
  p.call e
end

callback("hello from proc", Proc.new do |e|
  puts e
end)
=end

on :key_down do |e|
  puts "key_down: #{e.key_code}."
end

on :key_down { |e| puts "key down, code #{e.key_code}" }

callback = proc do |e|
  puts "proc callback, key up #{e.key_code}."
end

on(:key_up, &callback)

md = Proc.new { |e| puts "mouse_down #{e.type}" }

TopSprite.graphics.begin_fill(0x443344)
TopSprite.graphics.draw_rect(0,0,300,300)

# there is a bug in the implementation of Proc.new that is showing up here:
#on(:mouse_down, &md)

# same bug showing up here:
#on(:mouse_down, Proc.new { |e| puts "mouse_down #{e.type}" })

