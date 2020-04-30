# bibframe2marc design notes

_bibframe2marc_ is designed to be part of a conversion pipeline for converting BIBFRAME RDF descriptions to MARC records. By limiting the scope of the conversion to striped RDF/XML to MARCXML, the main intellectual work of specifying the conversion can be separated from all the mechanics of RDF dereferencing and inference and MARC format conversion, leaving those tasks to a wrapper application.

The schema for constructing conversion rules (see [rules.md](rules.md)) is designed to allow for specifying a conversion based on XPath matching of the RDF/XML document.

## Background: What goes into a MARC record

MARC21 bibliographic records can be constructed from an striped RDF/XML document with the following characteristics:

* Exactly 1 top-level `bf:Instance` subject
* 0 or 1 top-level `bf:Work` subject
  * The `bf:Work` subject, if it exists, must be linked with the `bf:Instance` entity, either as the object of a `bf:instanceOf` predicate, or as the subject of a `bf:hasInstance` predicate.

An RDF graph with these characteristics is referred to as a BIBFRAME "description" for simplicity's sake.

This converter takes BIBFRAME descriptions and transforms them into MARC21 records.

## Conversion wrapper

A sample application that uses _bibframe2marc_ is included with the [Biblio::BF2MARC](https://github.com/lcnetdev/biblio-bf2marc) perl module.

* The wrapper script takes an RDF graph of BIBFRAME descriptions and attempts to coerce it into a set of RDF/XML documents with 2 nodes:
  * `<bf:Instance>`
  * `<bf:Work>`
* These nodes refer to each other through the `bf:instanceOf` and `bf:hasInstance` predicates.
* Objects are dereferenced, so that all the required data is in the RDF/XML documents
* The wrapper script passes the RDF/XML documents to an XSLT stylesheet for transformation to MARCXML (one at a time).
* The wrapper script returns a MARC21 collection of bibliographic records in MARCXML.
