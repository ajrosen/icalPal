Each of the human-readable formats uses an [RDoc::Markup::Formatter](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Formatter.html) to render the output.

Each item to be printed is an [RDoc::Markup::Document](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Document.html). The document includes a section header (when using one of the _separate by_ options) and the item's properties.

A section header contains:

* [Blank line](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/BlankLine.html) (unless this is the first section)
* [Heading](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Heading) (level 1, the property's value)
* [Horizontal rule](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Rule.html)

An item's first property is a [bullet](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Raw.html) and a [heading](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Heading) (level 2) for the property's value.  Subsequent properties are shown as an unordered definition [list](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/List.html), with one [list item](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/ListItem.html) for each property.

A [blank line](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/BlankLine.html) is printed before the next item.  Each list item's label is the property's name.  The list item's contents is the property's value, rendered as a [paragraph](https://ruby-doc.org/stdlib-2.6.10/libdoc/rdoc/rdoc/RDoc/Markup/Paragraph.html).
