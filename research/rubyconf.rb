require "research/asterism.rb"
require "research/ui_fmwk.rb"
require "research/slideshow.rb"

# puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.main_screen
#puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.native_window.x = ms.bounds.x
AIRWindow.native_window.y = ms.bounds.y
AIRWindow.native_window.width = 300 || ms.bounds.width
AIRWindow.native_window.height = 300 || ms.bounds.height

include Geometry

top = Mx::Core::UIComponent.new
TopSprite.add_child(top)

show = SlideShow.new(top)

Red=DrawStyle.new
Red.line_thickness = 2
Red.line_color = 0xFFFFFF
Red.line_alpha = 1
Red.fill = true
Red.fill_color = 0xDD6644
Blue = Red.clone
Blue.fill_color = 0x4466FF
Blue.fill_alpha = 1

RedLine = DrawStyle.new
RedLine.line_thickness = 10
RedLine.line_color = 0xFF0000
RedLine.line_alpha = 1

show.new_slide do
  slide_text=<<HERE
<p class='lf'>Left align</p>
<p class='rt'>Right align</p>
<p class='lf'>Left align</p>
<p class='rt'>Right align</p>
HERE
  slide_text.each_line do |line|
    render { self.html_text += line}
  end
end

show.new_slide do
  slide_text=<<HERE
<body><h1>Overview</h1>
<p class='lf'>Introduction</p>
<p class='rt'>(5 mins)</p>
<p class='lf'>Overview</p>
<p class='rt'>(5 mins)</p>
<p class='lf'>Detailed Slides</p>
<p class='rt'>(20 mins)</p>
<p class='lf'>Demo</p>
<p class='rt'>(&lt;5 mins)</p>
<p class='lf'>Q&A</p>
<p class='rt'>(10 mins)</p></body>
HERE
  slide_text.each_line do |line|
    render { self.html_text += line}
  end
  render do
    @cover = new_slide_part
    line(x:50, y:50, x2:@width-50, y2:@height-50, style:RedLine).draw(@cover.sprite)
    line(x:@width-50, y:50, x2:50, y2:@height-50, style:RedLine).draw(@cover.sprite)
  end
end

show.new_slide do
  slide_text=<<HERE
<body><h1>Overview</h1>
<p class='lf'>Lame Joke</p>
<p class='rt'>(5 mins)</p>
<p class='lf'>Demo and Q&amp;A</p>
<p class='rt'>(40 mins)</p></body>
HERE
  slide_text.each_line do |line|
    render { self.html_text += line}
  end
end

new_text_input = proc do
    a = Text.new
    a.text_field.selectable = true
    a.text_field.type = :input
    a.text_field.background = true
    a.text_field.background_color = 0xFFFFFF
    a.text_field.text_color = 0x000000
    a.text_field.border = true
    a.text_field.border_color = 0x333333
end

show.new_slide do
  render do
    a = new_text_input.call
    a.x = 10
    a.y = 30
    a.width = 100
    a.height = 20
    sprite.add_child(a.text_field)
    b = Text.new
    b.x = 20
    b.y = 50
    b.text = "Name"
    sprite.add_child(b.text_field)
  end
end

show.new_slide do
  render do
    @left, @right = split_horizontal 30
    rectangle(:x=>0, :y=>80, :width=>60,
              :height=>20, :style=>Red).draw(@left.sprite)
    @right.ruby_code =<<HERE
show.new_slide do
  render do
    @left, @right = split_horizontal 30
    rectangle(:x=>0, :y=>80, :width=>60,
              :height=>20, :style=>Red).draw(@left.sprite)
    @right.ruby_code =HERE
  end
  render do
    circle(:x=>150, :y=>80, 
           :radius=>60, :style=>Blue ).draw(@right.sprite)
  end
    
end
HERE
  end
  render do
    circle(:x=>150, :y=>80, 
           :radius=>60, :style=>Blue ).draw(@left.sprite)
  end
    
end

show.start
#show.next_slide
#show.next_slide
#show.next_slide
