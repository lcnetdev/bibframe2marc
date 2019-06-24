.PHONY : all test_compile test_rules test check clean distclean

XSLTPROC = xsltproc
XSPEC = xspec.sh
TARGET_XSL = bibframe2marc.xsl

bibframe2marc.xsl : rules.xml
	$(XSLTPROC) src/compile.xsl rules.xml > $(TARGET_XSL)

all : bibframe2marc.xsl test

rules.xml : $(shell find rules)
	./buildrules.sh

test_compile :
	$(XSPEC) test/compile.xspec

test_named_templates : bibframe2marc.xsl
	$(XSPEC) test/named-templates.xspec

test_rules : bibframe2marc.xsl
	$(XSPEC) rules/test/rules.xspec

test : test_compile test_named_templates test_rules

check : test

clean :
	-rm rules.xml bibframe2marc.xsl

distclean : clean
	-find . -name "xspec" | xargs rm -r
