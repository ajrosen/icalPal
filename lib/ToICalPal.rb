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

  # @param opts [Hash] Used for conditional formatting
  # @option opts [String] :bullet Bullet
  # @option opts [String] :ab Alert bullet
  # @option opts [Boolean] :nb No bullet
  # @option opts [Boolean] :nc No calendar names
  # @option opts [Boolean] :npn No property names
  # @option opts [Integer] :palette (nil) 8 for \-f, 24 for \--color
  # @option opts [Array<String>] :ps List of property separators
  # @option opts [String] :ss Section separator
  def initialize(opts)
    super
    @opts = opts
  end

  # Start a new document
  def start_accepting
    @res = []
    @ps = 0
  end

  # Close the document
  def end_accepting
    @res.join
  end

  # Add a bullet for the first property of an item
  #
  # @param _arg [Array] Ignored
  def accept_list_start(_arg)
    begin
      return if @item['placeholder']

      if (@item['due_date'] + ICalPal::ITIME).between?(ICalPal::ITIME + 1, $now.to_i)
        @res << "#{@opts[:ab]} " unless @opts[:nb]
        return
      end
    rescue
    end

    @res << "#{@opts[:bullet]} " unless @opts[:nb]
  end

  # Add a property name
  #
  # @param arg [RDoc::Markup::ListItem]
  # @option arg [String] .label Contains the property name
  def accept_list_item_start(arg)
    @res << (@opts[:ps][@ps] || '    ') unless @item['placeholder']
    @res << colorize(*LABEL_COLOR, arg.label) << ': ' unless @opts[:npn] || NO_LABEL.any?(arg.label)

    @ps += 1 unless @ps == @opts[:ps].count - 1
  end

  # Add a blank line
  #
  # @param *_arg [Array] Ignored
  def accept_blank_line(*_arg)
    @res << "\n"
  end

  # Add either a section header or the first property of an item
  #
  # @param h [RDoc::Markup::Heading]
  # @option h [Integer] :level 1 for a section header
  # @option h [Integer] :level 2 for a property name
  # @option h [String] :text The header's text
  def accept_heading(h)
    h.text = colorize(@item['symbolic_color_name'], @item['color'], h.text) if (h.level == 2) || COLOR_LABEL.any?(@prop)
    @res << h.text

    case h.level
    when 1
      @res << ':'
    when 2
      if @prop == 'title' && @item['calendar']
        @res << bold(" (#{@item['calendar']})") unless @opts[:nc] || @item['title'] == @item['calendar']
      end
    end
  end

  # Add the property value
  #
  # @param p [RDoc::Markup::Paragraph]
  # @option p [Array<String>] :parts The property's text
  def accept_paragraph(p)
    t = p.parts.join('; ').gsub("\n", "\n    ")
    t = colorize(*DATE_COLOR, t) if @prop == 'datetime'
    @res << t
  end

  # Add a section separator
  #
  # @param _weight Ignored
  def accept_rule(_weight)
    @res << @opts[:ss]
    accept_blank_line
  end

  # Don't add anything to the document, just save the item for later
  #
  # @param arg [RDoc::Markup::Verbatim]
  # @option arg [Object] :format The item
  def accept_verbatim(arg)
    @item = arg.format
  end

  # Don't add anything to the document, just save the property name
  # for later
  #
  # @param arg [RDoc::Markup::Raw]
  # @option arg [Object] :parts The property
  def accept_raw(arg)
    @prop = arg.parts[0]
  end

  # @param str [String]
  # @return [String] str with increased intensity[#BOLD]
  def bold(str)
    return str unless @opts[:palette]

    BOLD + str + NORM
  end

  # @param c8 [String] Color used for \-f
  # @param c24 [String] Color used for \--color
  # @return [String] str in color, depending on opts[#]
  def colorize(c8, c24, str)
    return str unless c8 && c24 && @opts[:palette]

    case @opts[:palette]
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
