
[![CircleCI](https://circleci.com/gh/lcnetdev/bibframe2marc/tree/master.svg?style=svg)](https://circleci.com/gh/lcnetdev/bibframe2marc)
# bibframe2marc

XSLT 1.0 conversion from RDF/XML [BIBFRAME 2.0](http://www.loc.gov/bibframe/) to [MARCXML](http://www.loc.gov/marcxml/).

* [Introduction](#introduction)
* [Dependencies](#dependencies)
* [Usage](#usage)
  * [Conversion rules](#conversion-rules)
  * [Building](#building)
  * [Using the generated conversion stylesheet](#using-the-generated-conversion-stylesheet)
  * [Using the compiler stylesheet](#using-the-compiler-stylesheet)
  * [Tests](#tests)
* [TODO](#todo)
* [Known issues](#known-issues)
* [See also](#see-also)
* [License](#license)

## Introduction

_bibframe2marc_ consists of an [XSLT 1.0 stylesheet](src/compile.xsl) that takes a set of [XML rules](rules) and compiles them into another stylesheet (bibframe2marc.xsl). The conversion stylesheet takes an RDF/XML document representing a single BIBFRAME 2.0 description and converts it to a MARCXML document. The bibframe2marc.xsl stylesheet can be used as part of a conversion pipeline, as for example with the [Biblio::BF2MARC](https://github.com/lcnetdev/biblio-bf2marc) perl library.

## Dependencies

### Run-time dependencies

* [exsl:node-set()](http://exslt.org/exsl/functions/node-set/index.html) -- the XSLT processor that will process the generated `bibframe2marc.xsl` stylesheet must support the `node-set()` function in order to use the `map` rules element.

### Build dependencies

* [libxslt](http://xmlsoft.org/XSLT) -- specifically `xsltproc` -- is used by the root level `Makefile` to construct the `bibframe2marc.xsl` conversion stylesheet from the rules in the [rules](rules) subdirectory. Any XSLT 1.0 processor should be able to build the conversion stylesheet.

* [XSpec](https://github.com/xspec/xspec) is the test framework for both the rules compiler and the conversion spreadsheet. It is used by the root level `Makefile` for the `test` targets.

* A Java JRE and the Saxon XSLT and XQuery processor are required by XSpec. For more information, see the installation pages on the [XSpec wiki](https://github.com/xspec/xspec/wiki).

## Usage

### Conversion rules

The included set of [conversion rules](rules) represent an implementation of the [BIBFRAME to MARC conversion specifications](http://www.loc.gov/bibframe/bftm), maintained by the Library of Congress. The rules are implemented using an XML-based domain specific language -- the RDF2MARC Conversion Language. For details on the conversion language, see the [RDF2MARC rules documentation](doc/rules.md). For convenience, the conversion specifications are included in the [specs](specs) directory of this repository as Excel spreadsheets.

### Building

`make` in the root level of the working directory will create the `bibframe2marc.xsl` conversion stylesheet from the rules in the `rules` subdirectory. The destination stylesheet filename and path can be configured with the `TARGET_XSL` variable.

### Using the generated conversion stylesheet

The `bibframe2marc.xsl` conversion stylesheet is an XSLT 1.0 application that converts a striped RDF/XML document containing a single BIBFRAME 2.0 "description" (defined as an RDF graph composed of exactly one top-level `bf:Instance` subject and one or zero top-level `bf:Work` subjects, linked using the `bf:hasInstance` or `bf:instanceOf` properties). It can be invoked as a standalone application using an XSLT 1.0 processor such as `xsltproc`, or it can be embedded in another application using a library such as `libxslt` for processing, as with the [Biblio::BF2MARC](https://github.com/lcnetdev/biblio-bf2marc) perl library.

For more information about what consitutes a BIBFRAME description, see the [design notes](doc/design.md).

The converion stylesheet can take the following parameters:

* `pRecordId` -- an internal system record ID for use (for example) in a MARC 001 control field. If `pRecordId` is not provided, the conversion will use the `generate-id()` function to generate a record ID.

* `pCatScript` -- string for the default cataloging script found in `xml:lang` attributes. Defaults to `Latn`.

* `pGenerationTimestamp` -- a timestamp for the conversion. If it is not provided, and if the `date:date-time()` function is available, it will be created from the value of `date:date-time()`.

* `pSourceRecordId` -- parameter to set the source record ID, for use in conversion rules. Used in generating the [884](rules/10-8XX.xml).

* `pConversionAgency` -- parameter to set the conversion agency (default "DLC"), for use in conversion rules. Used in generating the [884](rules/10-8XX.xml).

* `pGenerationUri` -- parameter to set the generation URI (default "https://github.com/lcnetdev/bibframe2marc"). Used in generating the [884](rules/10-8XX.xml).

* `pSRULookup` -- parameter can be the string "true" or "false" (default "false"). If "true", use SRU to retrieve MARC authorities from the Library of Congress' SRU service instead of retrieving them directly by URL. This workaround is required for XSLT engines that have only rudimentary HTTP support (i.e., no HTTPS -- specifically, libxslt).

### Using the compiler stylesheet

The conversion stylesheet is generated from the rules in the `rules` subdirectory by the compiler stylesheet `src/compile.xsl`. You can adapt the sample conversion provided to your own needs, or create your own conversion rules. For more information, see the [RDF2MARC rules documentation](doc/rules.md).

To build a conversion stylesheet from a rules file, you can just run the compiler stylesheet with an XSLT 1.0 processor. For example, using `xsltproc`:

```
xsltproc src/compile.xsl rules.xml > bibframe2marc.xsl
```

### Tests

The compiler stylesheet has XSpec tests written for it that can be run with `make test_compile` (assuming that XSpec is installed and configured). The tests are in the `tests` subdirectory.

Named templates for data conversion that are generated by the compiler stylesheet can be tested with `make test_named_templates`.

The rules in the `rules` subdirectory can be tested using XSpec with `make test_rules`. Rules tests are in the `rules/tests` subdirectory.

The `test` target of the Makefile runs `test_compile`, `test_named_templates`, and `test_rules`.

## TODO

* A formal XML schema for the conversion rules still needs to be written

## Known issues

* The rules compiler uses the `xsl:namespace-alias` element of XSLT to allow for generating a conversion stylesheet. The behavior of this element differs depending on your XSLT processor. libxslt (xsltproc) uses the same namespace prefix in the source stylesheet as the namespace prefix in the output stylesheet, switching the namespace underneath. The Saxon XSLT processor switches out both the namespace prefix and the namespace itself. This results in slightly different output stylesheets -- but the actual BIBFRAME to MARC transformation is exactly the same. `compile.xsl` has been written to work most smoothly with `xsltproc`.

## See also

* [Issue tracker](https://github.com/lcnetdev/bibframe2marc/issues) on GitHub
* [Conversion rules documentation](doc/rules.md)
* [Design notes](doc/design.md)
* [Biblio::BF2MARC](https://github.com/lcnetdev/biblio-bf2marc) -- a perl library that uses _bibframe2marc_ for BIBFRAME to MARC conversion
* The [Bibliographic Framework Initiative](http://www.loc.gov/bibframe/) at the Library of Congress
* The MARC to BIBFRAME conversion tool ([marc2bibframe2](https://github.com/lcnetdev/marc2bibframe2))

## License
As a work of the United States government, this project is in the public domain within the United States.

Additionally, we waive copyright and related rights in the work worldwide through the CC0 1.0 Universal public domain dedication.

[Legal Code (read the full text)](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.
...
