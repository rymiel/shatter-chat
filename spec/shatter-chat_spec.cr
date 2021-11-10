require "./spec_helper"

def test_json_ansi(json_string, expected)
  h = JSON.parse(json_string).as_h
  r = Shatter::Chat::AnsiBuilder.new.read h
  r.should eq(expected)
end

describe Shatter::Chat::AnsiBuilder do
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
      %(\e[91mone \e[94mtwo \e[91mthree\e[0m)
    )
  end

  it "applies (temporary) translatable" do
    test_json_ansi(
      %({"translate": "chat.key", "color": "green", "with": [{"text": "arg1"}, {"text": "arg2", "color": "red"}]}),
      %(\e[92m<chat.key>\e[39;7m %( \e[0m\e[92marg1\e[39;7m , \e[0m\e[91marg2\e[39;7m ) \e[0m)
    )
  end
end
