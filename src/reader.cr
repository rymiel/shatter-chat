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
    abstract class LangReader
      abstract def keys : Hash(String, String)
    end

    class MojangAssetLangReader < LangReader
      @@memo : Hash(String, String)? = nil
      def initialize(@language_code = "en_us")
      end

      def keys : Hash(String, String)
        if memo = @@memo
          memo
        else
          memo = MojangAssets::LauncherMeta.get_language_file @language_code
          @@memo = memo
          memo
        end
      end
    end

    class LocalFileLangReader < LangReader
      def initialize(@file_name = "chat.json")
      end

      def keys : Hash(String, String)
        File.open @file_name { |f| Hash(String, String).from_json f }
      end
    end

    class NilLangReader < LangReader
      def keys : Hash(String, String)
        Hash(String, String).new
      end
    end

    getter builder : Builder(T)

    def initialize(@builder, @lang_reader = MojangAssetLangReader.new)
    end

    private def read_generic(obj : JSON::Any)
      g = convert_generic obj
      read g unless g.nil?
    end

    private def convert_generic(obj : JSON::Any) : Hash(String, JSON::Any)?
      if h = obj.as_h?
        return h
      elsif a = obj.as_a?
        return if a.size == 0
        first = convert_generic(a[0])
        return first if a.size == 1 || first.nil?
        additional = a[1..]
        first["extra"] = JSON::Any.new((first["extra"]?.try &.as_a || [] of JSON::Any) + additional)
        return first
      elsif s = obj.as_s?
        return {"text" => JSON::Any.new s}
      else raise TypeCastError.new("Cannot use #{obj.class} as a chat component")
      end
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
      if translate = obj["translate"]?.try &.as_s
        extra = obj["with"]?.try &.as_a
        @builder.push_translatable(@lang_reader.keys[translate]? || translate)
        extra.try &.each_with_index { |e|
          @builder.push_argument
          read_generic e
        }
        @builder.apply_translation
      else
        @builder.add_text obj["text"]?.to_s
        obj["extra"]?.try &.as_a.each { |e| read_generic e }
      end
      @builder.pop_multiple pending
      @builder
    end
  end
end
