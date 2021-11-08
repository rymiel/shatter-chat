require "colorize"

struct Colorize::Object(T)
  private MODE_ITALIC = '3'
  private MODE_STRIKETHROUGH = '9'
  private MODE_ITALIC_FLAG = 64
  private MODE_STRIKETHROUGH_FLAG = 128

  def italic
    @mode |= MODE_ITALIC_FLAG
    self
  end

  def strikethrough
    @mode |= MODE_STRIKETHROUGH_FLAG
    self
  end

  # Overridden to add italic
  private def self.append_start(io, color)
    last_color_is_default =
      @@last_color[:fore] == ColorANSI::Default &&
        @@last_color[:back] == ColorANSI::Default &&
        @@last_color[:mode] == 0

    fore = color[:fore]
    back = color[:back]
    mode = color[:mode]

    fore_is_default = fore == ColorANSI::Default
    back_is_default = back == ColorANSI::Default
    mode_is_default = mode == 0

    if fore_is_default && back_is_default && mode_is_default && last_color_is_default || @@last_color == color
      false
    else
      io << "\e["

      printed = false

      unless last_color_is_default
        io << MODE_DEFAULT
        printed = true
      end

      unless fore_is_default
        io << ';' if printed
        fore.fore io
        printed = true
      end

      unless back_is_default
        io << ';' if printed
        back.back io
        printed = true
      end

      unless mode_is_default
        # Can't reuse MODES constant because it has bold/bright duplicated
        {% for name in %w(bold dim underline blink reverse hidden italic strikethrough) %}
          if mode.bits_set? MODE_{{name.upcase.id}}_FLAG
            io << ';' if printed
            io << MODE_{{name.upcase.id}}
            printed = true
          end
        {% end %}
      end

      io << 'm'

      true
    end
  end
end