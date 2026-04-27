require 'rdoc'

##################################################
# Render an RDoc::Markup::Document, closely mimicking
# icalBuddy[https://github.com/ali-rantakari/icalBuddy]
class RDoc::Markup::ToICalPal < RDoc::Markup::Formatter
  # Standard
  # ANSI[https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-T.416-199303-I!!PDF-E&type=items]
  # colors
  ANSI = {
    black:   30,  '#000000': '38;5;0',
    red:     31,  '#ff0000': '38;5;1',
    green:   32,  '#00ff00': '38;5;2',
    yellow:  33,  '#ffff00': '38;5;3',
    blue:    34,  '#0000ff': '38;5;4',
    magenta: 35,  '#ff00ff': '38;5;5',
    cyan:    36,  '#00ffff': '38;5;6',
    white:   37,  '#ffffff': '38;5;255',
    default: 39,  custom: nil,

    # Reminders custom colors
    brown:     '38;2;162;132;94',
    gray:      '38;2;91;98;106',
    indigo:    '38;2;88;86;214',
    lightblue: '38;2;90;200;250',
    orange:    '38;2;255;149;0',
    pink:      '38;2;255;45;85',
    purple:    '38;2;204;115;225',
    rose:      '38;2;217;166;159',
  }.freeze

  # Increased intensity
  BOLD = format('%c[1m', 27.chr)

  # Default rendition
  NORM = format('%c[0m', 27.chr)

  # Properties for which we don't include labels
  NO_LABEL = %w[ title datetime ].freeze

  # Properties that are always colorized
  COLOR_LABEL = %w[ title calendar ].freeze

  # Default color for labels
  LABEL_COLOR = [ 'cyan', '#00ffff' ].freeze

  # Color for datetime value
  DATE_COLOR = [ 'yellow', '#ffff00' ].freeze

  # Accessors for constants
  def NO_LABEL() NO_LABEL end
  def COLOR_LABEL() COLOR_LABEL end
  def LABEL_COLOR() LABEL_COLOR end
  def DATE_COLOR() DATE_COLOR end

  # Start a new document
  def start_accepting
    @res = []
    @ps = 0
  end

  # Close the document
  def end_accepting
    @res.join
  end

  # Add a list
  #
  # @param _arg [Array] Ignored
  def accept_list_start(_arg) end

  # Add a property name
  #
  # @param arg [RDoc::Markup::ListItem]
  # @option arg [String] .label Contains the property name
  def accept_list_item_start(arg)
    @res << (@options[:ps][@ps] || '    ')
    @res << colorize(*LABEL_COLOR, arg.label) << ': ' unless @options[:npn] || NO_LABEL.any?(arg.label)

    @ps += 1 unless @ps == @options[:ps].count - 1
  end

  # Add a blank line
  #
  # @param _arg [Array] Ignored
  def accept_blank_line(*_arg)
    @res << "\n"
  end

  # Add a heading
  def accept_heading(h)
    @res << h.text
  end

  # Add a paragraph
  #
  # @param p [RDoc::Markup::Paragraph]
  # @option p [Array<String>] :parts The property's text
  def accept_paragraph(p)
    @res << p.parts.join('; ').gsub("\n", "\n    ")
  end

  # Add a section separator and a blank line
  #
  # @param _weight Ignored
  def accept_rule(_weight)
    @res << @options[:ss]
    accept_blank_line
  end

  # Add raw text
  #
  # @param arg [RDoc::Markup::Raw]
  def accept_raw(arg)
    @res << arg.parts
  end

  # @param str [String]
  # @return [String] str with increased intensity[#BOLD]
  def bold(str)
    return str unless @options[:palette]

    BOLD + str + NORM
  end

  # @param c8 [String] Color used for \-f
  # @param c24 [String] Color used for \--color
  # @return [String] str in color, depending on opts[#]
  def colorize(c8, c24, str)
    return str unless c8 && c24 && @options[:palette]

    case @options[:palette]
    when 8                      # Default colour table
      c = ANSI[c8.downcase.to_sym]
      c ||= ANSI[c24[0..6].downcase.to_sym]
      c ||= ANSI[:white]

    when 24                     # Direct colour in RGB space
      rgb = c24[1..].split(/(\h\h)(\h\h)(\h\h)/)
      rgb.map! { |i| i.to_i(16) }
      c = [ 38, 2, rgb[1..] ].join(';')
    end

    # esc c str esc ansi
    format('%<esc>c[%<color>sm%<string>s%<esc>c[%<ansi_default>sm',
           { esc: 27.chr, color: c, string: str, ansi_default: ANSI[:default] })
  end

  # @!visibility private

  # @param _a [Array] Ignored
  def accept_list_end(_a) end

  # @param _a [Array] Ignored
  def accept_list_item_end(_a) end

end
