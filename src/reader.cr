require "string_scanner"

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

  LEGACY_COLOR_MAP = {
    '0' => :black,
    '1' => :dark_blue,
    '2' => :dark_green,
    '3' => :dark_aqua,
    '4' => :dark_red,
    '5' => :dark_purple,
    '6' => :gold,
    '7' => :gray,
    '8' => :dark_gray,
    '9' => :blue,
    'a' => :green,
    'b' => :aqua,
    'c' => :red,
    'd' => :light_purple,
    'e' => :yellow,
    'f' => :white
  } of Char => NamedColor

  enum Decoration
    Bold
    Italic
    Underlined
    Strikethrough
    Obfuscated
    Special
  end

  LEGACY_DECORATION_MAP = {
    'k' => :obfuscated,
    'l' => :bold,
    'm' => :strikethrough,
    'n' => :underlined,
    'o' => :italic,
    'r' => :special
  } of Char => Decoration
  LEGACY_REGEX = /\x{00A7}#{Regex.union(LEGACY_COLOR_MAP.keys.map(&.to_s) + LEGACY_DECORATION_MAP.keys.map(&.to_s))}/

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

    def read(obj : Hash(String, JSON::Any), *, legacy = true) : Builder(T)
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
        if legacy
          read_legacy_text obj["text"]?.to_s
        else
          @builder.add_text obj["text"]?.to_s
        end
        obj["extra"]?.try &.as_a.each { |e| read_generic e }
      end
      @builder.pop_multiple pending
      @builder
    end

    private def read_legacy_text(s : String)
      scanner = StringScanner.new s
      did_push_color = false
      did_push_deco = 0
      loop do
        m = scanner.scan_until LEGACY_REGEX
        break if m.nil?
        matching_marker = m[-1]
        previous_text = m[..-3]
        @builder.add_text previous_text unless previous_text.empty?
        if color_marker = LEGACY_COLOR_MAP[matching_marker]?
          if did_push_deco > 0
            @builder.pop_multiple did_push_deco
            did_push_deco = 0
          end
          @builder.pop if did_push_color
          @builder.push_color color_marker
          did_push_color = true
        end
        if deco_marker = LEGACY_DECORATION_MAP[matching_marker]?
          if deco_marker.special?
            @builder.pop_multiple did_push_deco
            @builder.pop if did_push_color
            did_push_deco = 0
            did_push_color = false
          else
            @builder.push_decoration deco_marker, true
            did_push_deco += 1
          end
        end
      end
      rest = scanner.rest
      @builder.add_text rest unless rest.empty?
      @builder.pop_multiple did_push_deco
      @builder.pop if did_push_color
    end
  end
end
