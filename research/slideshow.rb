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

TopSprite.graphics.begin_fill(0x111111)
TopSprite.graphics.draw_rect(0,0,10000,10000)
TopSprite.graphics.end_fill()
TopSprite.graphics.begin_fill(0xFFFFFF,0)

include Geometry
=end

class SlideShow
  attr_accessor :frame, :slides, :index, :end
  def initialize(parent)
    @parent = parent
    @frame = Flash::Display::Sprite.new
    @parent.add_child(@frame)
    @slides = []
    @cur_frame = nil
    @end = Slide.new
    etf = Text.new
    etf.text = "END"
    @end.sprite.add_child(etf.text_field)

  end
  def add(sl)
    @slides << sl
  end
  def new_slide
    slide = Slide.new
    yield slide
    add(slide)
  end
  def first_slide
    @index = -1
    next_slide
  end
  def last_slide
    @index = @slides.length
    next_slide
  end
  def next_slide
    @frame.remove_child(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index + 1 if @index < @slides.length
    @cur_frame = Flash::Display::Sprite.new
    if @index < @slides.length
      sl = @slides[@index]
      sl.parent = @cur_frame
    else
      sl = @end
      sl.parent = @cur_frame
    end
    @frame.add_child(@cur_frame)
  end
  def prev_slide
    @frame.remove_child(@cur_frame) if @cur_frame
    @cur_frame = nil
    @index = @index - 1 if @index > 0
    return if @index >= @slides.length
    return if @index < 0
    @cur_frame = Flash::Display::Sprite.new
    sl = @slides[@index]
    sl.parent = @cur_frame
    @frame.add_child(@cur_frame)
  end
end
    

class Slide
  attr_accessor :layout, :children, :sprite
  include PropValidator
  def parent=(v)
    v.add_child(sprite)
  end
  def initialize
    @sprite = Flash::Display::Sprite.new
    @do = @sprite
  end
  def commitProperties()
  end
  def draw(obj)
    obj.draw(@sprite)
  end
  def split_horizontal()
    left = Canvas.new
    right = Canvas.new
    [left, right]
  end
end

class SlideShow
  def start

    scale = AIRWindow.native_window.width/200.1/2
    @parent.scaleX = @parent.scaleY = scale

    AIRWindow.on :window_resize do |e|
      scale = e.after_bounds.width/200.1/2
      #puts "#{e.after_bounds.width} x #{e.after_bounds.height} scale: #{scale}" 
      @parent.scaleX = @parent.scaleY = scale
    end

    @was_fullscreen = false

    # NOTE: Avoiding return from block which generates throw bytecode
    @parent.on :key_down do |e|
      puts "key code #{e.key_code}"
      done = false
      if e.key_code == 37 and e.command_key
        first_slide
        done = true
      end
      if not done
        if e.key_code == 39 and e.command_key
          last_slide
          done = true
        end
      end
      if not done
        next_slide if e.key_code == 39 or e.key_code == 13 or e.key_code == 32
        prev_slide if e.key_code == 37
        exit_fullscreen_or_close if e.key_code == 27
        toggle_fullscreen if e.key_code == 70
      end
    end

    AIRWindow.on :window_activate do |e|
      @parent.set_focus()
    end

    @parent.set_focus()

    @index = -1
    next_slide

end

def toggle_fullscreen
  if (@parent.stage.display_state == "fullScreen" or
      @parent.stage.display_state == "fullScreenInteractive") then
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
  @was_fullscreen = false
end

end
