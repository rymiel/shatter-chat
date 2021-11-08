require "./ext"
require "json"
require "colorize"

module Shatter::Chat
  extend self
  VERSION = "0.1.0"

  MC_EXTRA_COLORIZE = {
    "black"        => :black,
    "dark_blue"    => :blue,
    "dark_green"   => :green,
    "dark_aqua"    => :cyan,
    "dark_red"     => :red,
    "dark_purple"  => :magenta,
    "gold"         => :yellow,
    "gray"         => :light_gray,
    "dark_gray"    => :dark_gray,
    "blue"         => :light_blue,
    "green"        => :light_green,
    "aqua"         => :light_cyan,
    "red"          => :light_red,
    "light_purple" => :light_magenta,
    "yellow"       => :light_yellow,
    "white"        => :default,
  }

  private def color_string(text, color)
    color_symbol = if !color.nil? && color[0] == '#'
      r = color[1..2].to_u8 16
      g = color[3..4].to_u8 16
      b = color[5..6].to_u8 16
      Colorize::ColorRGB.new(r, g, b)
    else
      MC_EXTRA_COLORIZE.fetch(color, :default)
    end
    return text.colorize.fore(color_symbol)
  end

  def component(obj : Hash(String, JSON::Any))
    String.build do |str|
      colorized = color_string((obj.fetch("text", nil).try &.as_s).to_s, obj.fetch("color", nil).try &.as_s)
      {% for decoration in { {:bold,          "bold"},
                             {:italic,        "italic"},
                             {:underline,     "underlined"},
                             {:strikethrough, "strikethrough"},
                             {:blink,         "obfuscated"} } %}
        colorized = colorized.{{ decoration[0].id }} if obj[{{ decoration[1] }}]?.try &.as_bool
      {% end %}
      str << colorized
      if extra = obj.fetch("extra", nil)
        extra.as_a.each { |e| str << component e.as_h }
      end
    end
  end

  def component_from_json_string(s : String)
    component JSON.parse(s).as_h
  end
end
