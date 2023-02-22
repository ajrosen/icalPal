# icalPal

## Description

icalPal is a command-line tool to query a macOS Calendar database for
accounts, calendars, and events.  It can be run on any system with
[Ruby](https://www.ruby-lang.org/) and access to a Calendar database
file.

## Installation

<code>gem install icalPal</code>


## Usage

ical: Usage: ical [options] [-c] COMMAND

COMMAND must be one of the following:

    events                  Print events
    calendars               Print calendars
    accounts                Print accounts

    eventsToday             Print events occurring today
    eventsToday+NUM         Print events occurring between today and NUM days into the future
    eventsNow               Print events occurring at present time

Global options:

    -c, --cmd=COMMAND       Command to run
        --db=DB             Use DB file instead of Calendar
        --cf=FILE           Set config file path (default: $HOME/.icalPal)
    -o, --output=FORMAT     Print as FORMAT (default: default)
                            [ansi, csv, default, hash, html, json, md, rdoc, toc, yaml]

Including/excluding calendars:

        --is=ACCOUNTS       List of accounts to include
        --es=ACCOUNTS       List of accounts to exclude

        --it=TYPES          List of calendar types to include
        --et=TYPES          List of calendar types to exclude
                            [Local, Exchange, CalDAV, MobileMe, Subscribed, Birthdays]

        --ic=CALENDARS      List of calendars to include
        --ec=CALENDARS      List of calendars to exclude

Choosing dates:

        --from=DATE         List events starting on or after DATE
        --to=DATE           List events starting on or before DATE
                            DATE can be yesterday, today, tomorrow, +N, -N, or anything accepted by DateTime.parse()
                            See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-c-parse

    -n                      Include only events from now on
        --days=N            Show N days of events, including start date
        --sed               Show empty dates with --sd
        --ia                Include only all-day events
        --ea                Exclude all-day events

Choose properties to include in the output:

        --iep=PROPERTIES    List of properties to include
        --eep=PROPERTIES    List of properties to exclude
        --aep=PROPERTIES    List of properties to include in addition to the default list

        --uid               Show event UIDs
        --eed               Exclude end datetimes

        --nc                No calendar names
        --npn               No property names
        --nrd               No relative dates

    Properties are listed in the order specified

    Use 'all' for PROPERTIES to include all available properties (except any listed in --eep)
    Use 'list' for PROPERTIES to list all available properties and exit

Formatting the output:

        --li=N              Show at most N items (default: 0 for no limit)

        --sc                Separate by calendar
        --sd                Separate by date
        --sep=PROPERTY      Separate by PROPERTY

        --sort=PROPERTY     Sort by PROPERTY
    -r, --reverse           Sort in reverse

        --ps=SEPARATORS     List of property separators
        --ss=SEPARATOR      Set section separator

        --df=FORMAT         Set date format
        --tf=FORMAT         Set time format
                            See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-i-strftime for details

    -b, --ab=STRING         Use STRING for bullets
        --nnr=SEPARATOR     Set replacement for newlines within notes

    -f                      Format output using standard ANSI colors
        --color             Format output using a larger color palette

Help:

    -h, --help              Show this message
    -V, -v, --version       Show version and exit (1.0)
    -d, --debug=LEVEL       Set the logging level (default: warn)
                            [debug, info, warn, error, fatal]

Environment variables:

    ICALPAL                 Additional arguments
    ICALPAL_CONFIG          Additional arguments from a file
                            (default: $HOME/.icalPal)


## History

If you've found this page it's likely you've heard of [icalBuddy](https://github.com/ali-rantakari/icalBuddy):

> Command-line utility for printing events and tasks from the OS X calendar database.

I have used icalBuddy for many years.  It's great for scripting,
automation, and as a desktop widget for apps like
[GeekTool](https://www.tynsoe.org/geektool/) and
[Übersicht](https://tracesof.net/uebersicht/).

As with many applications, I started to run into some limitations in
icalBuddy.  The biggest being that active development ended over 8
years ago.  It's only thanks to the efforts of [Jim
Lawton](https://github.com/jimlawton) that it even compiles anymore.

Instead of trying to understand and extend the existing code, I chose
to start anew using my language of choice.

- Output in CSV, JSON, HTML, Markdown, and [more](#label-Output+formats)
- Enhanced color option[#label-Usage]
- Show and filter by Account
- Show and filter by Calendar type
- Select a different Calendar database
- Multi-platform
- Much less code (1200 lines vs. 7000)

I won't pretend to understand **why** you would want this on Linux or
Windows.  But since icalPal is written in Ruby and gets its data
directly from the Calendar database file instead of an API, you *can*.

## Output formats

icalPal supports several output formats.  The +default+ format tries
to mimic icalBuddy as much as possible.

CSV, Hash, JSON, and YAML print all fields for all items in their
respective formats.  From that you can analyze the results any way you like.

All other formats, ANSI, HTML, Markdown, RDoc, and TOC, use Ruby's
[RDoc::Markup](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup.html)
framework to build and render the items.

Each item to be printed is a new
[RDoc::Markup::Document](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Document.html).

When using one of the <em>separate by</em> options, a section header is added first.  The section contains:

* [RDoc::Markup::BlankLine](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/BlankLine.html)
  (unless this is the first section)
* RDoc::Markup::Heading (level 1)
* [RDoc::Markup::Rule](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Rule.html)

The rest of the document is a series of
[RDoc::Markup::List](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/List.html)
objects, one for each of the item's properties:

* [RDoc::Markup::List](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/List.html)
* RDoc::Markup::Heading (level 2)
* [RDoc::Markup::BlankLine](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/BlankLine.html)
* [RDoc::Markup::ListItem](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/ListItem.html)
* [RDoc::Markup::Paragraph](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Paragraph.html)

The document will also include a number of
[RDoc::Markup::Verbatim](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Verbatim.html)
items.  The are not included in the output, but are used to pass
information about the item and property to the default formatter.
