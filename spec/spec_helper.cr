require "spec"
require "../src/shatter-chat"

def test_json(json_string, expected)
  Shatter::Chat.component_from_json_string(json_string).should eq(expected)
end
