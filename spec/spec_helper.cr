require "spec"
require "../src/shatter-chat"
require "./spec_builder"

def test_json_ansi(json_string, expected)
  h = JSON.parse(json_string).as_h
  r = Shatter::Chat::AnsiBuilder.new.read h
  r.should eq(expected)
end

def test_json_html(json_string, expected)
  h = JSON.parse(json_string).as_h
  r = Shatter::Chat::HtmlBuilder.new.read h
  r.should eq(expected)
end

def test_json(json_string)
  actual = Shatter::Chat::SpecBuilder.new
  actual.read JSON.parse(json_string).as_h
  expected = Shatter::Chat::SpecBuilder.new
  yield expected
  expected.result
  actual.stack.should eq(expected.stack)
end
