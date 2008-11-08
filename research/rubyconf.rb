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

Backdrop = DrawStyle.new
Backdrop.fill = true
Backdrop.fill_color = 0x333333
Backdrop.line_thickness = 2
Backdrop.line_color = 0xDDDDDD
Backdrop.line_alpha = 1

RedLine = DrawStyle.new
RedLine.line_thickness = 10
RedLine.line_color = 0xFF0000
RedLine.line_alpha = 1

show.new_slide do
  slide_text=<<HERE
<body><h1>Red Sun - Flash Ruby VM</h1>
<p class='lf'>Introduction</p>
<p class='rt'>(5 mins)</p>
<p class='lf'>Overview</p>
<p class='rt'>(5 mins)</p>
<p class='lf'>Detailed Slides</p>
<p class='rt'>(25 mins)</p>
<p class='lf'>Demo</p>
<p class='rt'>(&lt;5 mins)</p>
<p class='lf'>Q&A</p>
<p class='rt'>(5 mins)</p></body>
HERE
  slide_text.each_line do |line|
    render { self.html_text += line}
  end
  render do
    @cover = new_sub_slide
    line(x:50, y:50, x2:@width-50, y2:@height-50, style:RedLine).draw(@cover)
    line(x:@width-50, y:50, x2:50, y2:@height-50, style:RedLine).draw(@cover)
  end
end

show.new_slide do
  slide_text=<<HERE
<body><h1>Red Sun - Flash Ruby VM</h1>
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
  a.text_field.on :focus_out do
    top.set_focus
  end
  a
end

new_field = proc do |parent, pos, name|
  x = pos[:x] || 0
  y = pos[:y] || 0
  a = new_text_input[]
  a.pos_size x:x+10, y:y+20, 
             width:100, height:20
  a.parent = parent
  b = Text.new
  b.pos_size x:x+20, y:y+40
  b.text = name
  b.parent = parent
end

show.new_slide do
  render do
    @left, @right = split_horizontal 35
    f = Canvas.new
    f.pos_size x:10, y:10
    rectangle(width:300,height:500,style:Backdrop).draw(f)
    f.parent = @left
    new_field[f, {x:10, y:10}, 'Name']
    new_field[f, {x:10, y:50}, 'Address']
    @right.ruby_code=<<HERE
f = Canvas.new
f.pos_size x:10, y:10
rectangle(width:300,height:500,
          style:Backdrop).draw(f)
f.parent = self
new_field[f, {x:10, y:10}, 'Name']
new_field[f, {x:10, y:50}, 'Address']
HERE
  end
  render do
    @right.ruby_code+=<<HERE
new_field = proc do |parent, pos, name|
  x = pos[:x] || 0
  y = pos[:y] || 0
  a = new_text_input[]
  a.pos_size x:x+10, y:y+20, 
             width:100, height:20
  a.parent = parent
  b = Text.new
  b.pos_size x:x+20, y:y+40
  b.text = name
  b.parent = parent
end
HERE
  end
end

show.new_slide do
  render do
    @left, @right = split_horizontal 30
    rectangle(:x=>0, :y=>80, :width=>60,
              :height=>20, 
              :style=>Red).draw(@left)
    @right.ruby_code =<<HERE
show.new_slide do
  render do
    @left, @right = split_horizontal 30
    rectangle(:x=>0, :y=>80, :width=>60,
              :height=>20, 
              :style=>Red).draw(@left)
    @right.ruby_code =HERE
  end

  render do
    circle(:x=>150, :y=>80, 
           :radius=>60, 
           :style=>Blue ).draw(@left)
  end
end
HERE
  end
  render do
    circle(:x=>150, :y=>80, 
           :radius=>60, 
           :style=>Blue ).draw(@left)
  end
end

show.new_slide do
  render do
    @left, @right = split_horizontal 60
    @left.ruby_code=<<HERE
class SlideShow
  def new_slide(&b)
    slide = setup_slide(Slide.new)
    slide.instance_exec(&b)
    add(slide)
  end
HERE
  end
  render do
    @left.ruby_code+=<<HERE
  def setup_slide(slide)
    slide.x = @h_pad
    slide.y = @v_pad
    slide.width = @width-@h_pad*2
    slide.height = @height-@v_pad*2
    slide
  end
HERE
  end
  render do
    @left.ruby_code+=<<HERE

  def add(slide)
    setup_slide(slide)
    @slides &lt;&lt; slide
    self
  end
end
HERE
  end
end

show.new_slide do
  render do
    self.ruby_code=<<HERE
class SubSlide
  def render(&r)
    if @parent_slide == self
      @parts &lt;&lt; r
    else
      me = self
      @parent_slide.render do 
        me.instance_exec(&r)
      end
    end
  end
end
HERE
  end
end

show.new_slide do
  render do
    self.ruby_code=<<HERE
class SlideShow
  def show
    @part_index = -1
    next_part
  end
  def next_part
    @parent.set_focus
    next_slide unless @slide and @slide.next_part
  end
end
HERE
  end
  render do
    self.ruby_code+=<<HERE
class Slide
  def next_part
    if @parts[@part_index+1]
      @part_index = @part_index+1
      @part = @parts[@part_index]
      self.instance_exec(&@part)
      true
    else
      false
    end
  end
end
HERE
  end
end

show.new_slide do
  render do
    @top = new_sub_slide
    @top.pos_size width:self.width, height:self.height
    @top.html_text="<body><h1>Ruby AS3 Bridge</h1></body>"
  end
  render do
    @bottom = new_sub_slide
    @bottom.pos_size y:100, width:self.width, height:self.height-100
    @bottom.ruby_code=<<HERE
AIRWindow.on :window_resize do |e|
  update_scale(e.after_bounds.width, e.after_bounds.height)
end
HERE
  end
  render do
    @bottom.ruby_code+=<<HERE
class SlideShow
  def update_scale(win_width, win_height)
    slide_aspect_ratio = @width.to_f/@height
    screen_aspect_ratio = win_width.to_f/win_height
    if slide_aspect_ratio > screen_aspect_ratio
      scale = win_width.to_f/@width
    else
      scale = win_height.to_f/@height
    end
    @frame.scale_x = @frame.scale_y = scale
  end
end
HERE
  end
end

show.new_slide do
  render do
    self.html_text=<<HERE
<body>
<h1>Why Ruby in Flash</h1>
<ul>
<li>More expressive, less code</li>
<li>Better reuse through Modules</li>
<li>Meta-programming</li>
<li>DSLs, DSLs, DSLs</li>
</ul>
</body>
HERE
  end
end

show.new_slide do
  render do
    self.html_text=<<HERE
<body><h1>Thanks</h1>
Jonathan Branam
      http://jonathanbranam.net

EffectiveUI
      http://effectiveui.com

Red Sun
      http://github.com/jonathanbranam/redsun
</body>
HERE
  end
end


show.start
=begin
show.next_slide
show.next_slide
show.next_slide
show.next_slide
show.next_slide
show.next_slide
show.next_slide
=end
