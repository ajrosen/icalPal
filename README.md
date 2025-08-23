[![Gem Version](https://badge.fury.io/rb/icalPal.svg)](https://badge.fury.io/rb/icalPal)

# icalPal

## Description

icalPal is a command-line tool to query macOS Calendar and Reminders
databases for accounts, calendars, events, and tasks.  It can be run
on any system with [Ruby](https://www.ruby-lang.org/) and access to a
Calendar or Reminders database.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Installation](#installation)
- [Features](#features)
  - [Additional commands](#additional-commands)
  - [Additional options](#additional-options)
  - [Additional properties](#additional-properties)
- [Usage](#usage)
- [Output formats](#output-formats)
- [History](#history)

<!-- markdown-toc end -->


## Installation

As a system-wide Ruby gem:

```
gem install icalPal
```

or in your home diretory:

```
gem install --user-install icalPal
```

## Features

### Compatability with icalBuddy

icalPal tries to be compatible with
[icalBuddy](https://github.com/ali-rantakari/icalBuddy) for
command-line options and for output.  There are a some important
differences to be aware of.

* Options require two hyphens, except for single-letter options that require one hyphen
* *eventsFrom* is not supported.  Instead there is *--from*, *--to*, and *--days*
* *uncompletedTasks* is simply *tasks*
* *undatedUncompletedTasks* is simply *undatedTasks*
* *tasksDueBefore:DATE* uses *--from*, *--to*, and *--days* instead of *:DATE*
* The command can go anywhere; it doesn't have to be the last argument
* Property separators are comma-delimited

### Additional commands

```icalPal accounts```

Shows a list of enabled Calendar accounts.  Internally they are known
as *Stores*; you can run ```icalPal stores``` instead.

```icalPal datedTasks```

Shows only reminders that have a due date.

```icalPal reminders```

*reminders*, *datedReminders*, *undatedReminders*, and
*remindersDueBefore* can be used instead of *tasks*

Reminders can also be viewed in the *Scheduled Reminders* calendar,
using the *tasks* commands.  Repeating reminders are treated the same
as repeating events.

### Additional options

* Options can be abbreviated, so long as they are unique.  Eg., ```icalPal -c ev --da 3``` is the same as ```icalPal -c events --days 3```.
* The ```-c``` part is optional, but you cannot abbreviate the command if you leave it off.
* Use ```-o``` to print the output in different formats.  CSV or JSON are interesting choices.
* Copy your Calendar or Reminders database file and use ```--db``` on it.
* ```--it``` and ```--et``` will filter by Calendar *type*.  Types are **Local**, **Exchange**, **CalDAV**, **MobileMe**, **Subscribed**, **Birthdays**, and **Reminders**
* ```--il``` and ```-el``` will filter by Reminder list
* ```--id``` includes completed reminders
* ```--ed``` excludes uncompleted reminders
* ```--ia``` includes *only* all-day events (opposite of ```--ea```)
* ```--aep``` is like ```--iep```, but *adds* to the default property list instead of replacing it.
* ```--sep``` to separate by any property, not just calendar (```--sc```) or date (```--sd```)
* ```--color``` uses a wider color palette.  Colors are what you have chosen in the Calendar and Reminders apps, including custom colors
* ```--match``` lets you filter the results of any command to items where a *FIELD* matches a regular expression.  Eg., ```--match notes=zoom.us``` to show only Zoom meeetings

Because icalPal is written in Ruby, and not a native Mac application,
you can run it just about anywhere.  It's been tested with the
versions of Ruby included with macOS Sequoia and Tahoe (2.6.10) and
[Homebrew](https://brew.sh/) (3.4.x).

### Additional properties

Several additional properties are available for each command.

* Accounts
  * account
  * notes
  * owner
  * type
  * delegations

* Calendar
  * account
  * shared\_owner_name, shared\_owner_address
  * self\_identity_email, owner\_identity_email
  * subcal_account_id, subcal_url
  * published_URL
  * notes
  * locale

* Tasks
	* id
	* grocery
	* completed
	* group
	* section
	* tags
	* assignee
	* timezone
	* Notifications
	  * due (due_date formatted with --df and --tf options)
	  * alert (Early Reminder)
	  * location, proximity (arriving or leaving), radius (in meters)
	  * messaging (email addresses and phone numbers from "When Messaging")

## Usage

icalPal: Usage: icalPal [options] [-c] COMMAND

COMMAND must be one of the following:
```
    events                  Print events
    tasks                   Print tasks
    calendars               Print calendars
    accounts                Print accounts

    eventsToday             Print events occurring today
    eventsToday+NUM         Print events occurring between today and NUM days into the future
    eventsNow               Print events occurring at present time
    eventsRemaining         Print events occurring between present time and midnight
    datedTasks              Print tasks with a due date
    undatedTasks            Print tasks with no due date
    tasksDueBefore          Print uncompleted tasks due between the given dates

    stores can be used instead of accounts
    reminders can be used instead of tasks
```

Global options:
```
    -c, --cmd=COMMAND       Command to run
        --db=DB             Use DB file instead of Calendar
                            (default: ["$HOME/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb", $HOME/Library/Calendars/Calendar.sqlitedb]
                            For the tasks commands this should be a directory containing .sqlite files
                            (default: "$HOME/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores")
        --cf=FILE           Set config file path (default: $HOME/.icalpal)
        --norc              Ignore ICALPAL and ICALPAL_CONFIG environment variables
    -o, --output=FORMAT     Print as FORMAT (default: default)
                            [ansi, csv, default, hash, html, json, md, rdoc, remind, toc, xml, yaml]
```

Including/excluding accounts, calendars, reminders and items:
```
        --is=ACCOUNTS       List of accounts to include
        --es=ACCOUNTS       List of accounts to exclude

        --it=TYPES          List of calendar types to include
        --et=TYPES          List of calendar types to exclude
                            [Local, Exchange, CalDAV, MobileMe, Subscribed, Birthdays]

        --ic=CALENDARS      List of calendars to include
        --ec=CALENDARS      List of calendars to exclude

        --il=LISTS          List of reminder lists to include
        --el=LISTS          List of reminder lists to exclude

        --id                Include completed reminders
        --ed                Exclude uncompleted reminders

        --match=FIELD=REGEX Include only items whose FIELD matches REGEXP (ignoring case)
```

Choosing dates:
```
        --from=DATE         List events starting on or after DATE
        --to=DATE           List events starting on or before DATE
                            DATE can be yesterday, today, tomorrow, +N, -N, or anything accepted by DateTime.parse()
                            See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-c-parse

    -n                      Include only events from now on
        --days=N            Show N days of events, including start date
        --sed               Show empty dates with --sd
        --ia                Include only all-day events
        --ea                Exclude all-day events
```

Choose properties to include in the output:
```
        --iep=PROPERTIES    List of properties to include
        --eep=PROPERTIES    List of properties to exclude
        --aep=PROPERTIES    List of properties to include in addition to the default list

        --itp=PROPERTIES    List of task properties to include
        --etp=PROPERTIES    List of task properties to exclude
        --atp=PROPERTIES    List of task properties to include in addition to the default list
                            Included for backwards compatability, these are aliases for --iep, --eep, and --aep

        --uid               Show event UIDs
        --eed               Exclude end datetimes

        --nc                No calendar names
        --npn               No property names
        --nrd               No relative dates

    Properties are listed in the order specified

    Use 'all' for PROPERTIES to include all available properties (except any listed in --eep)
    Use 'list' for PROPERTIES to list all available properties and exit
```

Formatting the output:
```
        --li=N              Show at most N items (default: 0 for no limit)

        --sc                Separate by calendar
        --sd                Separate by date
        --sp                Separate by priority
        --sep=PROPERTY      Separate by PROPERTY

        --sort=PROPERTY     Sort by PROPERTY
        --std               Sort tasks by due date (same as --sort=due_date)
        --stda              Sort tasks by due date (ascending) (same as --sort=due_date -r)
    -r, --reverse           Sort in reverse

        --ps=SEPARATORS     List of property separators
        --ss=SEPARATOR      Set section separator

        --df=FORMAT         Set date format
        --tf=FORMAT         Set time format
                            See https://ruby-doc.org/stdlib-2.6.1/libdoc/date/rdoc/DateTime.html#method-i-strftime for details

    -b, --bullet=STRING     Use STRING for bullets
        --ab=STRING         Use STRING for alert bullets
        --nb                Do not use bullets
        --nnr=SEPARATOR     Set replacement for newlines within notes

    -f                      Format output using standard ANSI colors
        --color             Format output using a larger color palette
```

Help:
```
    -h, --help              Show this message
    -V, -v, --version       Show version and exit (3.9.1)
    -d, --debug=LEVEL       Set the logging level (default: warn)
                            [debug, info, warn, error, fatal]
```

Environment variables:
```
    ICALPAL                 Additional arguments
    ICALPAL_CONFIG          Additional arguments from a file
                            (default: $HOME/.icalpal)

    Do not quote or escape values.  Options set in ICALPAL override ICALPAL_CONFIG.  Options on the command line override ICALPAL.
```

## Output formats

icalPal supports several output formats.  The **default** format tries
to mimic icalBuddy as much as possible.

CSV, Hash, JSON, XML, and YAML print all fields for all items in their
respective formats.  From that you can analyze the results any way you
like.  [Remind](https://dianne.skoll.ca/projects/remind/) format uses a
minimal implementation built into icalPal.

Control characters are escaped in these formats to ensure they remain
properly formatted.

Other formats such as ANSI, HTML, Markdown, RDoc, and TOC, use Ruby's
[RDoc::Markup](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup.html)
framework to build and render the items.

Each item to be printed is a new
[RDoc::Markup::Document](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Document.html).

When using one of the _separate by_ options, a section header is added
first.  The section contains:

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
and
[RDoc::Markup::Raw](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Raw.html)
items.  They are not included in the output, but are used to pass
information about the item and property to the default formatter.

## History

I used icalBuddy for many years.  It's great for scripting,
automation, and as a widget for apps like
[Übersicht](https://tracesof.net/uebersicht/),
[GeekTool](https://www.tynsoe.org/geektool/), and
[SketchyBar](https://felixkratz.github.io/SketchyBar/).

As with many applications, I started to run into some limitations in
icalBuddy.  The biggest being that active development ended in 2014.
It's only thanks to the efforts of [Jim
Lawton](https://github.com/jimlawton) that it even compiles anymore.

Instead of trying to understand and extend the existing code, I chose
to start anew using my language of choice:
[Ruby](https://www.ruby-lang.org).  Using Ruby meant there is *much*
less code; a little over 2,000 lines vs. 7,000.  It also means icalPal
is multi-platform.

I won't pretend to understand **why** you would want to run this on
Linux or Windows.  But since icalPal is written in Ruby and gets its
data directly from the Calendar and Reminders database files instead
of an API, you *can*.
