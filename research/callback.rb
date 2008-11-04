
def callback(e, &p)
  p.call e
end

callback("hello from proc") do |e|
  puts e
end
