# bibframe2marc-xsl design notes

_bibframe2marc-xsl_ is designed to be part of a conversion pipeline for converting BIBFRAME RDF descriptions to MARC records. By limiting the scope of the conversion to striped RDF/XML to MARCXML, the main intellectual work of specifying the conversion can be separated from all the mechanics of RDF dereferencing and inference and MARC format conversion, leaving those tasks to a wrapper application.

The schema for constructing conversion rules (see [rules.md](rules.md)) is designed to allow for specifying a conversion based on XPath matching of the RDF/XML document.

## Background: What goes into a MARC record

MARC21 bibliographic records can be constructed from an RDF graph with the following characteristics:

* One or more `bf:Instance` subjects with one or more `bf:instanceOf` predicates with a `bf:Work` object.
  * The `bf:instanceOf` predicate can also be calculated as the inverse of a `bf:hasInstance` predicate of a `bf:Work` subject.
  * Each `bf:Instance` to `bf:Work` relationship can generate a new MARC record.
    * A single `bf:Work` can be related to multiple `bf:Instance` nodes. The combination of the predicates of the `bf:Work` and each of the `bf:Instance` nodes can be used to construct multiple unique MARC21 bibliographic records.
      * Series and linking relationships (e.g. `bf:otherPhysicalFormat`, `bf:reproductionOf`) can be used to infer whether or not a unique MARC21 bibliographic record should be constructed.
    * A single `bf:Instance` can be related to multiple `bf:Work` nodes, but in general this _should not_ result in the construction of multiple unique MARC21 bibliographic records.
      * Series and linking relationships should be used to infer which `bf:Work` node should be used in the construction of the record.
      * If a "primary" `bf:Work` node can not be inferred, multiple records will be constructed.

An RDF graph with these characteristics is referred to as a BIBFRAME "description" for simplicity's sake.

This converter takes BIBFRAME descriptions and transforms them into MARC21 records.

## Conversion wrapper

A sample application that uses _bibframe2marc-xsl_ is included with the [Biblio::BF2MARC](https://github.com/lcnetdev/biblio-bf2marc) perl module.

* The wrapper script takes an RDF graph of BIBFRAME descriptions and attempts to coerce it into a set of RDF/XML documents with 2 nodes:
  * `<bf:Instance>`
  * `<bf:Work>`
* These nodes refer to each other through the `bf:instanceOf` and `bf:hasInstance` predicates.
* Objects are dereferenced, so that all the required data is in the RDF/XML documents
* The wrapper script passes the RDF/XML documents to an XSLT stylesheet for transformation to MARCXML (one at a time).
* The wrapper script returns a MARC21 collection of bibliographic records in MARCXML.
