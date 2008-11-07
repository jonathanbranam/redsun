
class ValidationManager
  attr_accessor :props, :size, :display
  def initialize
    @@vm = self
    @props = []
    @size = []
    @display = []
    vm = self
    TopSprite.on :enterFrame { |e| vm.validate }
  end
  def validate()
    props = @props
    @props = []
    props.each do |o|
      o.commit_properties() if o.respond_to? :commit_properties
    end
    size = @size
    @size = []
    size.each do |o|
      o.measure() if o.respond_to? :measure
    end
    display = @display
    @display = []
    display.each do |o|
      puts "Updating display for #{o}."
      o.update_display() if o.respond_to? :update_display
    end
  end
  def self.invalidate_properties(o)
    @@vm.props << o
  end
  def self.invalidate_size(o)
    @@vm.size << o
  end
  def self.invalidate_display(o)
    @@vm.display << o
  end
end

@vm = ValidationManager.new

module PropValidator
  def invalidate_properties()
    ValidationManager.invalidate_properties(self)
  end
  def commit_properties()
  end
end

module SizeInvalidation
  def invalidate_size()
    ValidationManager.invalidate_size(self)
  end
  def width=(w)
    super
    invalidate_size()
  end
  def height=(h)
    super
    invalidate_size()
  end
  def measure()
  end
end

module DisplayInvalidation
  def invalidate_display()
    ValidationManager.invalidate_display(self)
  end
  def invalidate_size()
    super
    invalidate_display()
  end
  def update_display()
  end
end

module PercentLayout
  attr_accessor :percent_width, :percent_height
  attr_accessor :explicit_width, :explicit_height
  def self.included(k)
    k.alias_method :super_width=, :width=
    k.alias_method :super_height=, :height=
  end
  def set_size(width, height)
    self.super_width = width
    self.super_height = height
  end
  def width=(width)
    super
    @explicit_width = width
  end
end

module DisplayObjectPassthrough
  def parent=(v)  v.add_child(@do); end
  def parent()    @do.parent;      end
  def x=(v)       @do.x = v;       end
  def x()         @do.x;           end
  def y=(v)       @do.y = v;       end
  def y()         @do.y;           end
  def width=(v)   @do.width = v;   end
  def width()     @do.width;       end
  def height=(v)  @do.height = v;  end
  def height()    @do.height;      end
end

module TextFieldPassthrough
  def text=(v)       @do.text = v;         end
  def text()         @do.text;             end
  def html_text=(v)  @do.html_text = v;    end
  def html_text()    @do.html_text;        end
end

module SizeBlock
  def width=(w)   @width = w;      end
  def width()     @width;          end
  def height=(h)  @height = h;     end
  def height()    @height;         end
end

class Text
  attr_accessor :text_field
  include DisplayObjectPassthrough
  include TextFieldPassthrough
  include PercentLayout
  def initialize
    @text_field = Flash::Text::TextField.new
    @do = @text_field
    @text_field.selectable = false
    @text_field.text_color = 0xFFFFFF
    self.font = "Courier New"
  end
  def font=(font_name)
    format = Flash::Text::TextFormat.new
    format.font = font_name
    @text_field.set_text_format(format)
  end
end

class HBox
  def layout(objects, width)
    total_percent = 0
    total_width = 0
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      total_percent += pw if pw
      total_width += w if not pw and w
    end
    percent_scale = total_percent/100.00001
    remaining_width = width
    percent_width = width - total_width
    puts "HBox pscale #{percent_scale}"
    # use up explicit space first
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      if not pw
        o.set_size(w, o.height)
        remaining_width -= w
      end
    end
    objects.each do |o|
      pw = o.percent_width if o.respond_to? :percent_width
      w = o.explicit_width || 0 if o.respond_to? :explicit_width
      if pw
        o.set_size(pw*percent_scale/100.00001*remaining_width, o.height)
      end
    end
  end
end

class Canvas
  attr_accessor :sprite
  include DisplayObjectPassthrough
  include SizeBlock
  include PercentLayout
  include SizeInvalidation
  include DisplayInvalidation
  def initialize
    @sprite = Flash::Display::Sprite.new
    @do = @sprite
  end
end

