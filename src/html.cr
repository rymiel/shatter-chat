require "html"

module Shatter::Chat
  class HtmlBuilder < Builder(String)
    HTML_COLOR_MAP = {
      NamedColor::Black       => "#000000",
      NamedColor::DarkBlue    => "#0000AA",
      NamedColor::DarkGreen   => "#00AA00",
      NamedColor::DarkAqua    => "#00AAAA",
      NamedColor::DarkRed     => "#AA0000",
      NamedColor::DarkPurple  => "#AA00AA",
      NamedColor::Gold        => "#FFAA00",
      NamedColor::Gray        => "#AAAAAA",
      NamedColor::DarkGray    => "#555555",
      NamedColor::Blue        => "#5555FF",
      NamedColor::Green       => "#55FF55",
      NamedColor::Aqua        => "#55FFFF",
      NamedColor::Red         => "#FF5555",
      NamedColor::LightPurple => "#FF55FF",
      NamedColor::Yellow      => "#FFFF55",
      NamedColor::White       => "#FFFFFF",
    }

    HTML_DECORATION_MAP = {
      Decoration::Bold          => "b",
      Decoration::Italic        => "i",
      Decoration::Underlined    => "u",
      Decoration::Obfuscated    => "blink",
      Decoration::Special       => "small",
      Decoration::Strikethrough => "strike",
    }

    @s = String::Builder.new
    @color_stack = [] of String
    @translation_stack = [] of String
    @argument_stack = [] of Array(String::Builder)
    @decoration_state = {} of String => Array(Bool)
    @stack = [] of {String, Array(String) | Array(Bool)}

    def push_color(c : NamedColor)
      color = HTML_COLOR_MAP[c]
      @color_stack << color
      current_output << "<span style=\"color:#{color}\">"
      @stack << {"</span>", @color_stack}
    end

    def push_rgb(r : UInt8, g : UInt8, b : UInt8)
      color = "##{r.to_s(16).rjust 2, '0'}#{g.to_s(16).rjust 2, '0'}#{b.to_s(16).rjust 2, '0'}"
      @color_stack << color
      current_output << "<span style=\"color:#{color}\">"
      @stack << {"</span>", @color_stack}
    end

    def push_decoration(d : Decoration, state : Bool)
      decoration_tag = HTML_DECORATION_MAP[d]
      deco = @decoration_state.fetch(decoration_tag, Array(Bool).new)
      deco << state
      current_output << "<#{decoration_tag}>" if state
      @stack << {state ? "</#{decoration_tag}>" : "", deco}
      @decoration_state[HTML_DECORATION_MAP[d]] = deco
    end

    def push_translatable(s : String)
      @translation_stack << s
      @argument_stack << Array(String::Builder).new
    end

    def push_argument
      @argument_stack.last << String::Builder.new
    end

    private def current_output
      @argument_stack.last?.try &.last? || @s
    end

    private def decorations
      @decoration_state.map { |k, v| v.last? ? k : nil }.compact
    end

    def add_text(s : String)
      HTML.escape s, current_output
    end

    def apply_translation
      i = -1
      args = @argument_stack.pop.map &.to_s
      current_output << @translation_stack.pop.gsub("%s") { |r|
        i += 1
        args[i]
      }
      if args.size > (i + 1)
        add_special " %extra( "
        args[i+1..].each_with_index do |j, k|
          add_special " , " if k > 0
          current_output << j
        end
        add_special " ) "
      end
    end

    def pop
      closing, a = @stack.pop
      a.pop
      current_output << closing
    end

    def result : String
      @s.to_s
    end
  end
end
