module Shatter::Chat
  enum NamedColor
    Black
    DarkBlue
    DarkGreen
    DarkAqua
    DarkRed
    DarkPurple
    Gold
    Gray
    DarkGray
    Blue
    Green
    Aqua
    Red
    LightPurple
    Yellow
    White
  end

  enum Decoration
    Bold
    Italic
    Underlined
    Strikethrough
    Obfuscated
    Special
  end

  class Reader(T)
    getter builder : Builder(T)

    def initialize(@builder)
    end

    def read(obj : Hash(String, JSON::Any)) : Builder(T)
      pending = 0
      color = obj.fetch("color", nil).try &.as_s
      if !color.nil? && color[0] == '#'
        r = color[1..2].to_u8 16
        g = color[3..4].to_u8 16
        b = color[5..6].to_u8 16
        @builder.push_rgb r, g, b
        pending += 1
      elsif color
        if named_color = NamedColor.parse? color
          @builder.push_color named_color
          pending += 1
        end
      end
      {% for member in Decoration.constants %}
        unless (v = obj[{{member.stringify.downcase}}]?).nil?
          @builder.push_decoration(Decoration::{{member}}, v.as_bool)
          pending += 1
        end
      {% end %}
      if translate = obj["translate"]?
        extra = obj["with"]?.try &.as_a
        @builder.add_text "<#{translate}>"
        @builder.add_special " %( " unless extra.nil?
        extra.try &.each_with_index { |e, i|
          @builder.add_special " , " if i > 0
          read e.as_h
        }
        @builder.add_special " ) " unless extra.nil?
      else
        @builder.add_text obj["text"]?.to_s
        obj["extra"]?.try &.as_a.each { |e| read e.as_h }
      end
      @builder.pop_multiple pending
      @builder
    end
  end
end
