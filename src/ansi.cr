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

    @s = String::Builder.new
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

    private def decorations
      @decoration_state.map { |k, v| v.last? ? k : nil }.compact
    end

    private def current_style(io : IO)
      color = @color_stack.last?
      return false if color.nil? && decorations.empty?
      io << "\e["
      case color
      when Int32 then io << color
      when RGB   then io << "38;2;" << color[:r] << ";" << color[:g] << ";" << color[:b]
      end
      io << ";" if color && !decorations.empty?
      decorations.join io, ";"
      io << 'm'
      return true
    end

    def add_text(s : String)
      has_style = current_style current_output
      current_output << s
      current_output << "\e[0m" if has_style
    end

    def apply_translation
      i = -1
      args = @argument_stack.pop.map &.to_s
      mem = IO::Memory.new
      current_style mem
      tr_style = mem.to_s
      add_text @translation_stack.pop.gsub("%s") { |r|
        i += 1
        args[i] + tr_style
      }.gsub(/%(\d+)\$s/) { |r| args[r[1].to_i-1] + tr_style }
      if args.size > (i + 1)
        add_special " %( "
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
      @s.to_s
    end
  end
end
