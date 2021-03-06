require "research/asterism.rb"
require "research/ui_fmwk.rb"

=begin
puts "Found #{Flash::Display::Screen.screens.length} screens."

ms = Flash::Display::Screen.main_screen
puts "Screen: #{ms.bounds.left} to #{ms.bounds.right} and #{ms.bounds.top} to #{ms.bounds.bottom}"

AIRWindow.native_window.x = ms.bounds.x
AIRWindow.native_window.y = ms.bounds.y
AIRWindow.native_window.width = 300 || ms.bounds.width
AIRWindow.native_window.height = 300 || ms.bounds.height

=end

class SlideShow
  attr_accessor :frame, :slides, :index, :end
  attr_accessor :width, :height
  def initialize(parent)
    @width = 1024
    @height = 768
    @h_pad = 50
    @v_pad = 50
    @parent = parent
    @frame = Flash::Display::Sprite.new
    @parent.add_child(@frame)
    @slides = []
    @cur_frame = nil

    @end = setup_slide(Slide.new)
    @end.html_text = "<font size='+40'>END</font>"

    self

  end
  def setup_slide(slide)
    slide.x = @h_pad
    slide.y = @v_pad
    slide.width = @width-@h_pad*2
    slide.height = @height-@v_pad*2
    slide
  end
  def add(slide)
    setup_slide(slide)
    @slides << slide
    self
  end
  def new_slide(&b)
    slide = setup_slide(Slide.new)
    slide.instance_exec(&b)
    add(slide)
  end
  def first_slide
    @index = -1
    next_slide
  end
  def last_slide
    @index = @slides.length
    next_slide
    self
  end
  def next_part
    @parent.set_focus
    next_slide unless @slide and @slide.next_part
  end
  def prev_part
    @parent.set_focus
    prev_slide unless @slide and @slide.prev_part
  end
  def next_slide
    @frame.remove_child(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index + 1 if @index < @slides.length
    @cur_frame = Flash::Display::Sprite.new
    if @index < @slides.length
      @slide = @slides[@index]
      @slide.show
      @slide.parent = @cur_frame
    else
      @slide = @end
      @slide.show
      @slide.parent = @cur_frame
    end
    @frame.add_child(@cur_frame)
    self
  end
  def prev_slide
    @frame.remove_child(@cur_frame) if @cur_frame
    @cur_frame = nil
    @slide = nil
    @index = @index - 1 if @index > 0
    return if @index >= @slides.length
    return if @index < 0
    @cur_frame = Flash::Display::Sprite.new
    @slide = @slides[@index]
    @slide.show
    @slide.parent = @cur_frame
    @frame.add_child(@cur_frame)
    self
  end
end

CodeCSS = <<HERE
code {
  font-family: Consolas;
  font-size: 28;
}
h1 {
  text-align: center;
  font-size: 70;
}
.rt {
  text-align: right;
  font-size: 50;
  margin-right: 90;
}
.lf {
  text-align: left;
  font-size: 50;
  leading: -60;
  margin-left: 90;
}
body {
  font-size: 30;
}
li {
  font-size: 50;
}


HERE

SlideSS = Flash::Text::StyleSheet.new
SlideSS.parseCSS(CodeCSS)

class SubSlide < Canvas
  attr_accessor :parent_slide
  include PropValidator
  def commitProperties()
  end
  def draw(obj)
    obj.draw(@sprite)
  end
  def width=(w)
    @text.width = w if @text
    super
  end
  def height=(h)
    @text.height = h if @text
    super
  end
  def check_text()
    if not @text
      @text = Text.new
      @text.width = self.width
      @text.height = self.height
      @text.text_field.style_sheet = SlideSS
      @text.parent = self
    end
  end
  def prettify_ruby_code(ht)
    "<code>#{ht}</code>"
  end
  def ruby_code
    html_text
  end
  def html_text
    if @text
      @text.html_text
    else
      ""
    end
  end
  def html_text=(ht)
    check_text
    @text.html_text = ht
  end
  def ruby_code=(ht)
    ht = prettify_ruby_code(ht)
    self.html_text = ht
  end
  def text=(t)
    check_text
    @text.text = t
  end
  def text()
    @text
  end
  def render(&r)
    if @parent_slide == self
      @parts << r
    else
      me = self
      @parent_slide.render do 
        me.instance_exec(&r)
      end
    end
  end
end

class Slide < SubSlide
  attr_accessor :layout, :children, :parts, :part_index
  def parent=(v)
    v.add_child(sprite)
  end
  def initialize
    super
    @children = []
    @parts = []
    @part_index = -1
    @parent_slide = self
  end
  def show
    @part_index = -1
    next_part
  end
  def new_sub_slide
    p = SubSlide.new
    p.parent_slide = self
    p.parent = self
    @children << p
    p
  end
  def split_horizontal(perc)
    perc = (perc || 50).to_f/100
    left = new_sub_slide
    left.width = self.width.to_f*perc
    left.height = self.height
    right = new_sub_slide
    right.x = left.width
    right.width = self.width.to_f*(1-perc)
    right.height = self.height
    [left, right]
  end
  def next_part
    if @parts[@part_index+1]
      @part_index = @part_index+1
      @part = @parts[@part_index]
      #d = @part
      self.instance_exec(&@part)
      true
    else
      false
    end
  end
  def prev_part
    target_index = @part_index - 1
    if target_index < 0
       false
    else
      ns = Flash::Display::Sprite.new
      if @sprite and @sprite.parent
        p = @sprite.parent
        p.remove_child(@sprite)
        p.add_child(ns)
      end
      @sprite = ns
      show
      next_part until @part_index >= target_index
      true
    end
  end
end

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

  def start

    update_scale(AIRWindow.native_window.width, AIRWindow.native_window.height)

    @frame.graphics.begin_fill(0x111111)
    @frame.graphics.draw_rect(0,0,10000,10000)
    @frame.graphics.end_fill()
    @frame.graphics.begin_fill(0xFFFFFF,0)

    @frame.graphics.line_style(5, 0xFFFFFF)
    @frame.graphics.begin_fill(0,0)
    @frame.graphics.draw_rect(1,1,@width-30,@height-2)
    @frame.graphics.end_fill()

    AIRWindow.on :window_resize do |e|
      update_scale(e.after_bounds.width, e.after_bounds.height)
    end

    @was_fullscreen = false
    @ignore_keydown = false

    # NOTE: Avoiding return from block which generates throw bytecode
    @parent.on :key_down do |e|
      puts "key code #{e.key_code}"
      done = false
      if @ignore_keydown
        done = true
        if e.key_code == 192
          @ignore_keydown = false
        end
      end
      if not done and not @ignore_keydown and e.key_code == 192
        @ignore_keydown = true
        done = true
      end
      if not done and e.key_code == 37 and e.command_key
        first_slide
        done = true
      end
      if not done and e.key_code == 39 and e.command_key
        last_slide
        done = true
      end
      if not done
        prev_slide if e.key_code == 38
        next_slide if e.key_code == 40
        next_part if e.key_code == 39 or e.key_code == 13 or e.key_code == 32
        prev_part if e.key_code == 37
        exit_fullscreen_or_close if e.key_code == 27 or e.key_code == 81
        toggle_fullscreen if e.key_code == 70
      end
    end

    AIRWindow.on :window_activate do |e|
      @parent.set_focus
    end

    @parent.set_focus

    @index = -1
    next_slide

  end

  def fullscreen?
    @parent and @parent.stage and
    (@parent.stage.display_state == "fullScreen" or
     @parent.stage.display_state == "fullScreenInteractive")
  end

  def toggle_fullscreen
    if fullscreen?
      @was_fullscreen = false
      @parent.stage.display_state = "normal"
    else
      @was_fullscreen = true
      @parent.stage.display_state = "fullScreenInteractive"
    end
  end

  def exit_fullscreen_or_close
    # stage.display_state has already changed before :key_down of ESC
    AIRWindow.close if not @was_fullscreen
    toggle_fullscreen if fullscreen?
    @was_fullscreen = false
  end

end
