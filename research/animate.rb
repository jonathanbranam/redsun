TopSprite.graphics.line_style(2, 0xFFFFFF, 1)
TopSprite.graphics.begin_fill(0x33AAEE)
TopSprite.graphics.draw_rect(5,5,105,105)

tf = Flash::Text::TextField.new
tf.text = "Hello!"
tf.x = 250
tf.y = 50
tf.selectable = false
tfor = Flash::Text::TextFormat.new
tfor.size = 25
tf.set_text_format(tfor)
TopSprite.add_child(tf)
wait(1)
tf.x = tf.x- 50
wait(1)
tf.x = tf.x- 50
wait(1)
tf.x = tf.x- 50
wait(1)
tf.x -= 50
wait(1)
tf.x -= 50
wait(1)
tf.x -= 50
wait(1)
tf.x -= 50

=begin

next_frame()

for_seconds(1.seconds) do 
  tf.alpha += 0.1
end

fadein = Tween.new(0,1) do |obj, val|
  obj.alpha = val
end

fadein.run(tf)


=end
