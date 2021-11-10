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
    @translation_stack = [] of String
    @argument_stack = [] of Array(String::Builder)
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

    def add_text(s : String)
      o = current_output
      color = @color_stack.last?
      decorations = @decoration_state.map { |k, v| v.last? ? k : nil }.compact
      if color.nil? && decorations.empty?
        o << "\e[0m" if @had_color || @had_decoration
        o << s
      else
        o << "\e[0m" if (@had_decoration && !decorations.any?) || (@had_color && color.nil?)
        o << "\e["
        case color
        when Int32 then o << color
        when RGB   then o << "38;2;" << color[:r] << ";" << color[:g] << ";" << color[:b]
        end
        o << ";" if color && !decorations.empty?
        decorations.join @s, ";"
        @had_decoration = !decorations.empty?
        @had_color = !color.nil?
        o << 'm'
        o << s
      end
    end

    def apply_translation
      i = -1
      args = @argument_stack.pop.map &.to_s
      current_output << @translation_stack.pop.gsub("%s") { |r|
        i += 1
        args[i]
      }
      if args.size > (i + 1)
        add_special " %extra( \e[0m"
        args[i+1..].each_with_index do |j, k|
          add_special " , " if k > 0
          current_output << j
        end
        add_special " ) "
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
