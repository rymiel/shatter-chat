require "spec"
require "../src/shatter-chat"

def test_json(json_string, expected)
  h = JSON.parse(json_string).as_h
  r = Shatter::Chat::AnsiBuilder.new.read h
  r.should eq(expected)
end
