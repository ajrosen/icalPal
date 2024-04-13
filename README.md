[![Gem Version](https://badge.fury.io/rb/icalPal.svg)](https://badge.fury.io/rb/icalPal)

# icalPal

## Description

icalPal is a command-line tool to query a macOS Calendar database for
accounts, calendars, and events.  It can be run on any system with
[Ruby](https://www.ruby-lang.org/) and access to a Calendar database
file.

## Installation

```
gem install icalPal
icalPal events
```

## Features

### Compatability with [icalBuddy](https://github.com/ali-rantakari/icalBuddy)

icalPal tries to be compatible with icalBuddy for command-line options
and for output.  There are a few differences to be aware of.

* Options require two hyphens, except for single-letter options that require one hyphen
* *eventsFrom* is not supported.  Instead there is *--from*, *--to*, and *--days*
* icalPal does not support the *tasks* commands yet
* The command can go anywhere; it doesn't have to be the last argument
* Property separators are comma-delimited

### Additional commands

```icalPal accounts```

Shows a list of enabled Calendar accounts.  Internally they are known as *Stores*; you can run ```icalPal stores``` instead.

### Additional options

* Options can be abbreviated, so long as they are unique.  Eg., ```icalPal -c ev --da 3``` is the same as ```icalPal -c events --days 3```.
* The ```-c``` part is optional, but you cannot abbreviate the command if you leave it off.
* Use ```-o``` to print the output in different formats.  CSV or JSON are intertesting choices.
* Copy your Calendar database file and use ```--db``` on it.
* ```--it``` and ```--et``` will filter by Calendar *type*.  Types are **Local**, **Exchange**, **CalDAV**, **MobileMe**, **Subscribed**, and **Birthdays**
* ```--ia``` includes *only* all-day events (opposite of ```--ea```)
* ```--aep``` is like ```--iep```, but *adds* to the default property list instead of replacing it.
* ```--sep``` to separate by any property, not just calendar (```--sc```) or date (```--sd```)
* ```--color``` uses a wider color palette.  Calendar colors are what you have chosen in the Calendar app.  Not supported in all terminals, but looks great in [iTerm2](https://iterm2.com/).

Because icalPal is written in Ruby, and not a native Mac application, you can run it just about anywhere.  It's been tested with version of Ruby (2.6.10) included with macOS, and does not require any external dependencies.

## Usage

icalPal: Usage: icalPal [options] [-c] COMMAND

COMMAND must be one of the following:

    events                  Print events
    tasks                   Print tasks
    calendars               Print calendars
    accounts                Print accounts

    eventsToday             Print events occurring today
    eventsToday+NUM         Print events occurring between today and NUM days into the future
    eventsNow               Print events occurring at present time
    undatedTasks            Print tasks with no due date

Global options:

    -c, --cmd=COMMAND       Command to run
        --db=DB             Use DB file instead of Calendar
        --cf=FILE           Set config file path (default: $HOME/.icalPal)
    -o, --output=FORMAT     Print as FORMAT (default: default)
                            [ansi, csv, default, hash, html, json, md, rdoc, toc, yaml, remind]

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

    -b, --bullet=STRING     Use STRING for bullets
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

I have used icalBuddy for many years.  It's great for scripting,
automation, and as a desktop widget for apps like
[GeekTool](https://www.tynsoe.org/geektool/) and
[Übersicht](https://tracesof.net/uebersicht/).

As with many applications, I started to run into some limitations in
icalBuddy.  The biggest being that active development ended in 2014.
It's only thanks to the efforts of [Jim
Lawton](https://github.com/jimlawton) that it even compiles anymore.

Instead of trying to understand and extend the existing code, I chose
to start anew using my language of choice.  Using Ruby means icalPal
is multi-platform.  It also meant *much* less code; about 1,200 lines
vs. 7,000.

I won't pretend to understand **why** you would want this on Linux or
Windows.  But since icalPal is written in Ruby and gets its data
directly from the Calendar database file instead of an API, you *can*.

## Output formats

icalPal supports several output formats.  The **default** format tries
to mimic icalBuddy as much as possible.

CSV, Hash, JSON, and YAML print all fields for all items in their
respective formats.  From that you can analyze the results any way you like.

[Remind](https://dianne.skoll.ca/projects/remind/) format uses a minimal implementation built in icalPal.

Other formats such as ANSI, HTML, Markdown, RDoc, and TOC, use Ruby's
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
items.  They are not included in the output, but are used to pass
information about the item and property to the default formatter.
