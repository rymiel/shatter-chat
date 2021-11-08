require "./spec_helper"

describe Shatter::Chat do
  Colorize.enabled = true
  it "applies simple color" do
    test_json(
      %({"text": "Hello, world!", "color": "red"}),
      %(\e[91mHello, world!\e[0m)
    )
  end

  it "applies simple decoration" do
    test_json(
      %({"text": "Hello, bold!", "bold": true}),
      %(\e[1mHello, bold!\e[0m)
    )
  end

  it "applies simple color and decoration pair" do
    test_json(
      %({"text": "Hello, both!", "color": "red", "bold": true}),
      %(\e[91;1mHello, both!\e[0m)
    )
  end

  it "respects false decorations" do
    test_json(
      %({"text": "Hello, no bold!", "color": "red", "bold": false}),
      %(\e[91mHello, no bold!\e[0m)
    )
  end
end
