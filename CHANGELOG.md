icalPal-4.1.1
==================

  * Fix semantic version check for dependencies (#51)
  * Fix relative date labels when TZ offset > 0 (#49, #50)

icalPal-4.1.0
==================

  * Add flags property for events in Scheduled Reminders
	* 0 (TODO) or 1 (Completed)

icalPal-4.0.0
==================

  * Support Ruby 4.0.0
  * Fixes for #45 and #46
  * Use RUBY_DESCRIPTION instead of RUBY_VERSION for posterity

icalPal-3.10.1
==================

  * Fix rounding/off-by-one errors in RDT
  * Regression bug fix for start_tz/end_tz
  * Regression bug fix for end dates of events with specifiers
  * Use utc_offset instead of timezone for reminders
  * Remove tzinfo dependency
  * Simplify tasks commands parsing

icalPal-3.10.0
==================

  * Add sharees property to calendars command
  * Fix defaults for tasks command variants
  * Move sorting logic to ICalPal classes
    * Fix sorting when a sort field is nil
    * Support "Others" section in reminders
  * Don't print section header if section is nil
  * Fix for DateTime not handling DST when adding days/weeks/months/years
  * Compute age using start_date

icalPal-3.9.3
==================

  * Fix for #35
  * Fix for #42
  * Honor --cf option when --norc is also given

  * Cleaner handling of eventsNow, eventsRemaining, and eventsToday commands
  * Move SQL error handling in lib/icalPal.rb to bin/icalPal
  * Handle SQLite3::SQLException in reminders (from Data-local.sqlite)
  * Switch from timezone to tzinfo
  * Switch $now from RDT to Time
  * Add day_start and day_end methods to RDT

icalPal-3.9.2
==================

  * Escape control characters in CSV and Remind output

icalPal-3.9.1
==================

  * Implement tasksDueBefore command
  * Add grocery and completed properties to tasks commands
  * Add --id and --ed options for tasks commands

icalPal-3.8.2
==================

  * Fix for #40

icalPal-3.8.1
==================

  * Fix sorting regression bug

icalPal-3.8.0
==================

  * Add properties for tasks commands
	* id
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

  * Limit properties for accounts command
	* account
	* notes
	* owner
	* type
	* delegations

  * Limit properties for calendar command
	* account
	* UUID
	* shared\_owner_name, shared\_owner_address
	* self\_identity_email, owner\_identity_email
	* subcal\_account_id, subcal_url
	* published_URL
	* notes
	* locale

  * New command aliases
	* reminders for tasks commands

  * Property aliases
	* name or title for account in accounts command
	* name or title for calendar in calendars command
	* name or event for title in events commands
	* name, reminder, or task for title in tasks commands

  * Bug fixes
	* Add additional properties from --iep/--aep with --iep/--aep all
	* Do not include properties twice
	* Adjust indentation of task properties to match icalBuddy
	* Sorting tasks
	* Handle Errno::EPERM (needs Full Disk Access) for Reminders database

icalPal-3.7.2
==================

  * atp, etp, and itp options were not aliases for aep, eep, and iep per the documentation

icalPal-3.7.1
==================

  * Fix stores command (#36)


icalPal-3.7.0
==================

  * Add sseconds/eseconds fields for easier post-processing

icalPal-3.6.1 / 2025-05-18
==================

  * aep, eep, and iep options were being applied to tasks commands

icalPal-3.6.0 / 2025-05-18
==================

  * Fix release/upload asset name of gem file
  * Version 3.6.0
  * Move dependencies to extconf.rb
  * "require 'nokogiri-plist'" could hang; use Plist instead.
  * Change 'UTC' to '+00:00' for Time.at
  * Add wrappers for require/require_relative to help debugging
  * Feature: `eventsRemaining` (#32)

icalPal-3.5.0 / 2025-05-13
==========================

  * Update version, README
  * Fix changes to recurring events when original event is in_window
  * Add --norc option (#31)
  * Norc (#30)

icalPal-3.4.0 / 2025-04-08
==========================

  * Version 3.4.0
  * Update comments
  * Homebrew formula bitrot
  * Fixes for multi-day events and specifiers with +/-
  * Handle option values with spaces in ICALPAL and ICALPAL_CONFIG
  * Add comment in help for option values with spaces
  * Set :to option time to 23:59:59 so end dates match
  * Add table of contents
  * Add reinstall target
  * Move dump to the module level for other klasses
  * Use new sctime and ectime fields for sorting events and displaying datetime
  * Make sure $opts is set before referencing it
  * Version 3.4.0.pre
  * Fix timezone dependency version
  * Fix bugs with recurring events

icalpal-3.4.0.pre / 2025-03-24
==============================

  * Use MFA with rubygems.org
  * Bugfix for eventsNow and -n option
  * Better error messages for sqlite3
  * Version 3.3.0
  * Use MFA with rubygems.org

icalpal-3.2.0 / 2025-02-15
==========================

  * Clean Gemfile
  * Clean workflow
  * Create rake
  * Add Gemfile
  * "RubyGems version (3.0.3.1) has a bug"
  * Use release-gem@v1
  * Publish to rubygems.org first
  * Add id-token: write permissions
  * icalPal -> icalpal
  * Use ruby version 2.6.10
  * Push gems to rubygems.org
  * Update lines of code count
  * Placate rubocop
  * Make sure at least one database is loaded
  * Merge pull request #24 from andregce/main
  * Update README.md

icalPal-3.1.1 / 2024-11-07
==========================

  * Fix for MacOS 15.1 (Sequoia). The calendar database was moved to a different folder.

icalPal-3.1.0 / 2024-09-11
==========================

  * Add GITHUB_REPO

icalpal-3.0.0 / 2024-09-11
==========================

  * Add release and upload targets
  * Check if a single event is longer than 100000 days
  * Set default color of Reminders
  * Get name from lib/version.rb
  * Make all references to icalpal lowercase
  * Update README.md

2.2.0 / 2024-05-15
==================

  * Bump version to 2.2.0
  * Fix recurring event specifier parsing
  * Add --match option

2.1.0 / 2024-04-28
==================

  * Bump version to 2.1.0
  * Fix XML output for Array fields (eg., xdate)
  * Stop processing multi-day events after --to date
  * Make SQLite3::SQLException non-fatal
  * Print useful error message for missing dependency
  * Add --user-install Ruby gem instruction
  * Fix issue #20
  * Add homebrew installation
  * Add test for tasks command
  * Merge branch 'main' of https://github.com/ajrosen/icalPal
  * Update README.md
  * Fix publish target

2.0.0 / 2024-04-13
==================

  * Merge branch 'main' of https://github.com/ajrosen/icalPal
  * Fix install with remote dependencies
  * Merge pull request #17 from ajrosen/reminders
  * Add tasks commands
  * Add dependency on nokogiri-plist
  * Get VERSION from lib/version.rb
  * Merge branch '11-add-xml-output-option' into reminders
  * Add tasks and undatedTasks commands

1.3.0-beta1 / 2024-04-09
========================

  * Add support for XML output

1.2.1 / 2024-04-06
==================

  * Merge pull request #14 from ajrosen/9-icalpal-hangs
  * Merge branch 'main' into 9-icalpal-hangs
  * Make sure specifiers always future times
  * Bump version number
  * Create icalPal-1.1.17.issue9.gem
  * Add lots of debug messages

1.2.0 / 2024-04-05
==================

  * Merge pull request #12 from ajrosen/10-problem-with-csv-export-for-recurring-events
  * Fix CSV output
  * Fix output of placeholder events

1.1.6 / 2024-03-28
==================

  * Fix issue #7
  * Update README.md

1.1.5 / 2024-03-16
==================

  * Version 1.1.5

1.1.4 / 2024-02-28
=================

  * Merge branch 'main' of https://github.com/ajrosen/icalPal
  * Version 1.1.4
  * Fix --bullet option (formerly --ab)
  * Merge pull request #6 from ajrosen/1.1.4
  * Add current timezone to $today
  * Uniq the rows before printing
  * Support "Subscribed" calendars
  * Update README.md
  * Add --bullet and remind output format
  * Fix -b/--bullet option, add --nb (no bullets)
  * No need to declare d1 for single use
  * Create Makefile
  * Add dependency on sqlite3
  * Merge pull request #3 from fgombault/Remind_output
  * added mention of remind format
  * added DURATION spec
  * fixed time spec (shouldn't include seconds)

1.1.3 / 2023-07-21
==================

  * Bump version to 1.1.3
  * Merge pull request #2 from fgombault/Remind_output
  * Added basic remind output format

1.1.2 / 2023-04-05
==================

  * Fix start/end times when start_tz is _float

1.1.1 / 2023-03-20
==================

  * Fix: Recurring events shown past "count" iterations

1.1.0 / 2023-03-05
==================

  * V1.1.0: Add output fields for external processing
  * Fix: Allow --cmd option in environment variable or config file
  * Improve non-markup output formats behavior and performance
  * Add tarball and checksums

1.0.3 / 2023-02-25
==================

  * Add test data

1.0.2 / 2023-02-24
==================

  * Use File.read instead of IO.read
  * Bump to 1.0.1 for README updates
  * Add Features, trim History
  * Add badge
  * Add files via upload
  * Initial commit
