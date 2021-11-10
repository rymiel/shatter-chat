module Shatter::Chat
  abstract class Builder(T)
    def reader_for_self : Reader(T)
      Reader(T).new self
    end

    def read(h) : T
      reader_for_self.read(h).result
    end

    abstract def push_color(c : NamedColor)
    abstract def push_rgb(r : UInt8, g : UInt8, b : UInt8)
    abstract def push_decoration(d : Decoration, state : Bool)
    abstract def add_text(s : String)
    abstract def pop
    abstract def result : T

    def pop_multiple(i)
      i.times { pop }
    end

    def add_special(s : String)
      push_color NamedColor::White
      push_decoration Decoration::Special, true
      add_text s
      pop_multiple 2
    end
  end
end
