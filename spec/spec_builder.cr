module Shatter::Chat
  class SpecBuilder < Builder(Nil)
    alias StackType = NamedColor | RGB | {Decoration, Bool} | String | {String, Array(Array(StackType))} | Array(StackType)
    @translation_stack = [] of String
    @argument_stack = [] of Array(Array(StackType))
    @current = [] of StackType
    getter stack = [] of StackType

    def push_color(c : NamedColor)
      current << c
    end

    def push_rgb(r : UInt8, g : UInt8, b : UInt8)
      current << {r: r, g: g, b: b}
    end

    def push_decoration(d : Decoration, state : Bool)
      current << {d, state}
    end

    def push_translatable(s : String)
      @translation_stack << s
      @argument_stack << Array(Array(StackType)).new
    end

    def push_argument
      @argument_stack.last << Array(StackType).new
    end

    def apply_translation
      args = @argument_stack.pop
      key = @translation_stack.pop
      current << {key, args}
    end

    def add_text(s : String)
      current << s
    end

    def pop
      stack << @current
      @current = [] of StackType
    end

    def result : Nil
      # stack << @current unless @current.empty?
      nil
    end

    private def current
      @argument_stack.last?.try &.last? || @current
    end
  end
end