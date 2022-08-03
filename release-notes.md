# bibframe2marc release notes

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

 
