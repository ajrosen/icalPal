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
