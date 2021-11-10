module Shatter::Chat
  class AnsiBuilder < Builder(String)
    ANSI_COLOR_MAP = {
      NamedColor::Black       => 30,
      NamedColor::DarkBlue    => 34,
      NamedColor::DarkGreen   => 32,
      NamedColor::DarkAqua    => 36,
      NamedColor::DarkRed     => 31,
      NamedColor::DarkPurple  => 35,
      NamedColor::Gold        => 33,
      NamedColor::Gray        => 37,
      NamedColor::DarkGray    => 90,
      NamedColor::Blue        => 94,
      NamedColor::Green       => 92,
      NamedColor::Aqua        => 96,
      NamedColor::Red         => 91,
      NamedColor::LightPurple => 95,
      NamedColor::Yellow      => 93,
      NamedColor::White       => 39,
    }

    ANSI_DECORATION_MAP = {
      Decoration::Bold          => 1,
      Decoration::Italic        => 3,
      Decoration::Underlined    => 4,
      Decoration::Obfuscated    => 5,
      Decoration::Special       => 7,
      Decoration::Strikethrough => 9,
    }

    alias RGB = {r: UInt8, g: UInt8, b: UInt8}
    @s = String::Builder.new
    @had_color = false
    @had_decoration = false
    @color_stack = [] of Int32 | RGB
    @decoration_state = {} of Int32 => Array(Bool)
    @stack = [] of Array(Int32 | RGB) | Array(Bool)

    def push_color(c : NamedColor)
      @color_stack << ANSI_COLOR_MAP[c]
      @stack << @color_stack
    end

    def push_rgb(r : UInt8, g : UInt8, b : UInt8)
      @color_stack << {r: r, g: g, b: b}
      @stack << @color_stack
    end

    def push_decoration(d : Decoration, state : Bool)
      deco = @decoration_state.fetch(ANSI_DECORATION_MAP[d], Array(Bool).new)
      deco << state
      @stack << deco
      @decoration_state[ANSI_DECORATION_MAP[d]] = deco
    end

    def add_text(s : String)
      color = @color_stack.last?
      decorations = @decoration_state.map { |k, v| v.last? ? k : nil }.compact
      if color.nil? && decorations.empty?
        @s << "\e[0m" if @had_color || @had_decoration
        @s << s
      else
        @s << "\e[0m" if @had_decoration && decorations.empty?
        @s << "\e[0m" if @had_color && color.nil?
        @s << "\e["
        case color
        when Int32 then @s << color
        when RGB   then @s << "38;2;" << color[:r] << ";" << color[:g] << ";" << color[:b]
        end
        @s << ";" if color && !decorations.empty?
        decorations.join @s, ";"
        @had_decoration = !decorations.empty?
        @had_color = !color.nil?
        @s << 'm'
        @s << s
      end
    end

    def pop
      t = @stack.pop.pop
    end

    def result : String
      @s << "\e[0m" if @had_color || @had_decoration
      @s.to_s
    end
  end
end
