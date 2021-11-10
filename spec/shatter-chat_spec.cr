require "./spec_helper"

module Shatter::Chat
  describe Shatter::Chat do
    it "reads no color" do
      test_json %({"text": "Hello, world!"}) do |i|
        i.add_text "Hello, world!"
      end
    end

    it "applies simple color" do
      test_json %({"text": "Hello, world!", "color": "red"}) do |i|
        i.push_color NamedColor::Red
        i.add_text "Hello, world!"
        i.pop
      end
    end
    
    it "applies rgb color" do
      test_json %({"text": "Hello, world!", "color": "#ff08ff"}) do |i|
        i.push_rgb r: 0xffu8, g: 0x08u8, b: 0xffu8
        i.add_text "Hello, world!"
        i.pop
      end
    end

    it "applies simple decoration" do
      test_json %({"text": "Hello, bold!", "bold": true}) do |i|
        i.push_decoration Decoration::Bold, true
        i.add_text "Hello, bold!"
        i.pop
      end
    end

    it "applies simple color and decoration pair" do
      test_json %({"text": "Hello, both!", "color": "red", "bold": true}) do |i|
        i.push_color NamedColor::Red
        i.push_decoration Decoration::Bold, true
        i.add_text "Hello, both!"
        i.pop_multiple 2
      end
    end

    it "respects false decorations" do
      test_json %({"text": "Hello, no bold!", "color": "red", "bold": false}) do |i|
        i.push_color NamedColor::Red
        i.push_decoration Decoration::Bold, false
        i.add_text "Hello, no bold!"
        i.pop_multiple 2
      end
    end

    it "inherits decorations" do
      test_json %({"text": "one ", "color": "red", "extra": [{"text": "two ", "color": "blue"}, {"text": "three"}]}) do |i|
        i.push_color NamedColor::Red
        i.add_text "one "
          i.push_color NamedColor::Blue
          i.add_text "two "
          i.pop
        i.add_text "three"
        i.pop
      end
    end

    it "applies translatable" do
      test_json %({"translate": "chat.type.advancement.task", "color": "green", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}]}) do |i|
        i.push_color NamedColor::Green
        i.push_translatable Reader::KEYS["chat"]["type.advancement.task"].as_s
        i.push_argument
          i.add_text "arg1"
        i.push_argument
          i.push_color NamedColor::Red
          i.add_text "arg2"
          i.pop
        i.apply_translation
        i.pop
      end
    end

    it "applies translatable with no root style" do
      test_json %({"translate": "chat.key", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}]}) do |i|
        i.add_text "<chat.key>"
        i.add_special " %( "
        i.add_text "arg1"
        i.add_special " , "
        i.push_color NamedColor::Red
        i.add_text "arg2"
        i.pop
        i.add_special " ) "
      end
    end
  end

  describe AnsiBuilder do
    Colorize.enabled = true

    it "reads no color" do
      test_json_ansi(
        %({"text": "Hello, world!"}),
        %(Hello, world!)
      )
    end

    it "applies simple color" do
      test_json_ansi(
        %({"text": "Hello, world!", "color": "red"}),
        %(\e[91mHello, world!\e[0m)
      )
    end

    it "applies rgb color" do
      test_json_ansi(
        %({"text": "Hello, world!", "color": "#ff08ff"}),
        %(\e[38;2;255;8;255mHello, world!\e[0m)
      )
    end

    it "applies simple decoration" do
      test_json_ansi(
        %({"text": "Hello, bold!", "bold": true}),
        %(\e[1mHello, bold!\e[0m)
      )
    end

    it "applies simple color and decoration pair" do
      test_json_ansi(
        %({"text": "Hello, both!", "color": "red", "bold": true}),
        %(\e[91;1mHello, both!\e[0m)
      )
    end

    it "respects false decorations" do
      test_json_ansi(
        %({"text": "Hello, no bold!", "color": "red", "bold": false}),
        %(\e[91mHello, no bold!\e[0m)
      )
    end

    it "inherits decorations" do
      test_json_ansi(
        %({"text": "one ", "color": "red", "extra": [{"text": "two ", "color": "blue"}, {"text": "three"}]}),
        %(\e[91mone \e[0m\e[94mtwo \e[0m\e[91mthree\e[0m)
      )
    end

    it "applies translatable" do
      test_json_ansi(
        %({"translate": "chat.type.advancement.task", "color": "green", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}]}),
        %(\e[92marg1\e[0m has made the advancement \e[91marg2\e[0m)
      )
    end

    it "applies oversized translatable" do
      test_json_ansi(
        %({"translate": "chat.type.advancement.task", "color": "green", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}, {"text": "arg3"}]}),
        %(\e[92marg1\e[0m has made the advancement \e[91marg2\e[0m\e[39;7m %extra( \e[0m\e[92marg3\e[0m\e[39;7m ) \e[0m)
      )
    end

    it "applies translatable with no root style" do
      test_json_ansi(
        %({"translate": "chat.key", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}]}),
        %(<chat.key>\e[39;7m %( \e[0marg1\e[39;7m , \e[0m\e[91marg2\e[0m\e[39;7m ) \e[0m)
      )
    end
  end
end
