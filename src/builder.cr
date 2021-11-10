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

    def pop_multiple(i)
      i.times { pop }
    end

    abstract def result : T
  end
end
