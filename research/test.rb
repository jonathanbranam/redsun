

fe = Flash::Events

puts "Flash::Events => #{fe}"

puts "Flash::Events.name => #{Flash::Events.name}"

puts "Flash::Events::Event => #{Flash::Events::Event}"

evt = Flash::Events::Event.new "keyDown"

puts "event: #{evt} #{evt.type} #{evt.bubbles}"

puts "Flash.name => #{Flash.name}"

puts "Flash::Display.name => #{Flash::Display.name}"
