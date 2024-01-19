# bibframe2marc release notes

## v2.5.0

Conversion updates based on specifications v2.5. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in the distribution in the spec directory. Changes of note:

* Numerous bug fixes.
* Added support for properties and classes moved from BFLC namespace to main BF namespace.
* Added support for 023 and 647.
* Support proper 264 ind1 value for serials and integrating resources. 
* Added support to dynamically lookup FAST and DNB headings.

See the [NEWS](NEWS) file for full details of changes.

## v2.4.0

Conversion updates based on specifications v2.4. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in the distribution in the spec directory. Changes of note:

* Resources that are split into multiple Instances during the marc2bibframe conversion are reassembled into a single MARC record with paired 007/300 fields. Reconstruction is outlined in the new “Process 4” instruction.
* Value from bflc:nonSortNum field is inserted into first or second indicator of MARC field.

See the [NEWS](NEWS) file for full details of changes.

## v2.3.0

Many, many bug fixes and conversion updates based on specifications v2.3. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details about spec changes. Specifications are included in the distribution in the spec directory. Changes of note:

* Use "\[not\] used by agency" statuses for 050, 055, 060, 070 to set indicator value properly.
* Accommodate use of main note pattern for Awards.
* Output 051 based on new classification pattern.
* Handle 561, 563, and 583 at Item or Instance level.
* Do not create empty 264 when bf:copyrightDate property has no value.
* Only output 310/321 if Frequency has data value.
* Fix bug with 630 non-filing characters.
* Fix bug where 7XX $i should be $4; set default relationship to 758 when indeterminable.
* Only output 5XX fields when there is content.

See the [NEWS](NEWS) file for full details of changes.

## v2.2.1

Patch release to address numerous bug issues. This still conforms with 2.2.0 specs, which can be found in the [spec](spec/) directory. Changes of note:

* Fix duplicating 7XXs.
* Set correct indicator values for 240, 730, and 830.
* Better handling of legacy 440.

See the [NEWS](NEWS) file for full details of changes.

## v2.2.0

Conversion updates based on specifications v2.2. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in the distribution in the spec directory. Changes of note:

* Support for bflc:marcKey property.
* Support for ID.LOC.GOV lookup support using Saxonica or MarkLogic XSLT processors.
* Partial support for Names, Subjects, and GenreForm lookups with xsltprocessor.
* Support for bflc:nonSortNum property.

See the [NEWS](NEWS) file and the [updated specifications](spec/) for full details of changes. Changes from v2.1.0 in the specifications are marked in red.

## v2.1.0

Conversion updates based on specifications v2.1. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in the distribution in the spec directory. Changes of note:

* Add support for converting bf:binding to 340$l.
* Make 040 subfield order:  $abecd 
* Add support for outputting 348.
* Ensure BF language notes go to 546.
* Update BF Series processing for appropriate 490 or Series 8XX fields.
* Output 242$y.

See the [NEWS](NEWS) file and the [updated specifications](spec/) for full details of changes. Changes from v2.0.0 in the specifications are marked in red.

## v2.0.0

Conversion updates based on specifications v2.0. See the Library of Congress’s [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in the distribution in the spec directory. Changes of note:

* Use new Work types to set Leader/06 and Leader/07 bytes.
* Use new 334 field for Issuance.
* Create 490 and 8XX fields from Hubs.
* Create 264 fields from bflc:simplePlace, bflc:simpleAgent and bflc:simplePlace literals.
* Create 720 fields when bf:agent has type Uncontrolled.
* Address issues a number of issues with too few 008 values (resulting in too-short 008s), incorrect 008 dates, and empty fields.

See the [NEWS](NEWS) file and the [updated specifications](spec/) for full details of changes. Changes from v1.1.1 in the specifications are marked in red.

## v1.1.1

Release to address numerous bug issues. This still conforms with 1.1.0 specs, which can be found in the [spec](spec/) directory. Changes of note:

* Address 008 spacing issues.
* Check for existing values before outputting field.
* Make sure various indicators set properly.

See the [NEWS](NEWS) file for full details of changes.


## v1.1.0

Conversion updates based on specifications v1.1.0. See the Library of Congress' [BIBFRAME site](https://www.loc.gov/bibframe/) for more details. Specifications are included in this distribution in the [spec](spec/) directory. Changes of note:

* Retaining punctuation in various fields (210, 222, 264, 245, etc.)
* Use new 344 for CaptureStorage and not 500.
* Add copyright symbol if Print, Arhival, Manuscript, Tactile, or Electronic.
* Numerous generation updates for 2XX, 3XX, 6XX, 7XX, etc. fields.

See the [NEWS](NEWS) file and the [updated specifications](spec/) for full details of changes.

 
