<xslt:stylesheet version="1.0"
                 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                 xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                 xmlns:marc="http://www.loc.gov/MARC21/slim"
                 xmlns:bf="http://id.loc.gov/ontologies/bibframe/"
                 xmlns:bflc="http://id.loc.gov/ontologies/bflc/"
                 xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
                 xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
                 xmlns:xsl="http://www.w3.org/1999/XSL/TransformAlias"
                 xmlns:bf2marc="http://www.loc.gov/bf2marc"
                 xmlns:local="http://example.org/local"
                 xmlns:exsl="http://exslt.org/common"
                 xmlns:xdmp="http://marklogic.com/xdmp"
                 exclude-result-prefixes="bf2marc">

  <xslt:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>
  <xslt:output encoding="UTF-8" method="xml" indent="yes"/>
  <xslt:preserve-space elements="bf2marc:text"/>
  <xslt:strip-space elements="*"/>

  <xslt:template match="/">
    <xsl:stylesheet version="1.0"
                    xmlns:exsl="http://exslt.org/common"
                    xmlns:date="http://exslt.org/dates-and-times"
                    xmlns:xdmp="http://marklogic.com/xdmp"
                    xmlns:fn="http://www.w3.org/2005/xpath-functions"
                    extension-element-prefixes="exsl date xdmp"
                    exclude-result-prefixes="fn rdf rdfs bf bflc madsrdf local">

      <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
      <xsl:strip-space elements="*"/>

      <xsl:param name="pRecordId" select="'default'"/>
      <xsl:param name="pCatScript" select="'Latn'"/>

      <!-- parameters for 884 generation -->
      <xsl:param name="pGenerationDatestamp">
        <xsl:choose>
          <xsl:when test="function-available('date:date-time')">
            <xsl:value-of select="concat(translate(substring(date:date-time(),1,19),'-:T',''),'.0')"/>
          </xsl:when>
          <xsl:when test="function-available('fn:current-dateTime')">
            <xsl:value-of select="concat(translate(substring(fn:current-dateTime(),1,19),'-:T',''),'.0')"/>
          </xsl:when>
        </xsl:choose>
      </xsl:param>
      <xsl:param name="pSourceRecordId"/>
      <xsl:param name="pConversionAgency" select="'DLC'"/>
      <xsl:param name="pGenerationUri" select="'https://github.com/lcnetdev/bibframe2marc'"/>
      <xsl:param name="pSRULookup"/>

      <!-- for upper- and lower-case translation (ASCII only) -->
      <xsl:variable name="lower">abcdefghijklmnopqrstuvwxyz</xsl:variable>
      <xsl:variable name="upper">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
      
      <xsl:variable name="xslProcessor">
        <!-- xsl:vendor, when compiled with xsltproc, works, meaning the output is xsl for elements and xsl:vendor and the tests pass. -->
        <!-- xsl:vendor, when compiled with saxon, fails, meaning the output is xslt for elements and xsl for xsl:vendor and 'xsl' has not been defined. -->
        <!-- xslt:vendor, when compiled with xsltproc, fails, meaning the output is xsl for elements and xslt for xslt:vendor. -->
        <!-- xslt:vendor, when compiled with saxon, works, meaning he output is xslt for elements and xslt for xslt:vendor. Tests pass. -->
        <xslt:choose>
          <xslt:when test="system-property('xslt:vendor') = 'libxslt'">
            <xsl:value-of select="system-property('xsl:vendor')" />
          </xslt:when>
          <xslt:otherwise>
            <xsl:value-of select="system-property('xslt:vendor')" />
          </xslt:otherwise>
        </xslt:choose>
      </xsl:variable>

      <xslt:apply-templates/>

      <!-- Conversion functions -->

      <xsl:template name="tChopPunct">
        <xsl:param name="pString"/>
        <xsl:variable name="vNormString" select="normalize-space($pString)"/>
        <xsl:variable name="vPunct" select="':;,/=&#x2013;&#x2014;'"/>
        <xsl:variable name="vEndEnclose" select="')]}}&quot;'"/>
        <xsl:variable name="vLength" select="string-length($vNormString)"/>
        <xsl:choose>
          <xsl:when test="$vLength=0"/>
          <xsl:when test="not($vNormString)"/>
          <!-- remove enclosing characters -->
          <xsl:when test="substring($vNormString,1,1) = '('">
            <xsl:variable name="vCloseIndex">
              <xsl:call-template name="tLastIndex">
                <xsl:with-param name="pString" select="$vNormString"/>
                <xsl:with-param name="pSearch" select="')'"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$vCloseIndex &gt; 2">
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="concat(substring($vNormString,2,$vCloseIndex - 2),substring($vNormString,$vCloseIndex+1))"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="substring($vNormString,2)"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="substring($vNormString,1,1) = '['">
            <xsl:variable name="vCloseIndex">
              <xsl:call-template name="tLastIndex">
                <xsl:with-param name="pString" select="$vNormString"/>
                <xsl:with-param name="pSearch" select="']'"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$vCloseIndex &gt; 2">
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="concat(substring($vNormString,2,$vCloseIndex - 2),substring($vNormString,$vCloseIndex+1))"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="substring($vNormString,2)"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="substring($vNormString,1,1) = '{{'">
            <xsl:variable name="vCloseIndex">
              <xsl:call-template name="tLastIndex">
                <xsl:with-param name="pString" select="$vNormString"/>
                <xsl:with-param name="pSearch" select="'}}'"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$vCloseIndex &gt; 2">
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="concat(substring($vNormString,2,$vCloseIndex - 2),substring($vNormString,$vCloseIndex+1))"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="substring($vNormString,2)"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="substring($vNormString,1,1) = '&quot;'">
            <xsl:variable name="vCloseIndex">
              <xsl:call-template name="tLastIndex">
                <xsl:with-param name="pString" select="$vNormString"/>
                <xsl:with-param name="pSearch" select="'&quot;'"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$vCloseIndex &gt; 2">
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="concat(substring($vNormString,2,$vCloseIndex - 2),substring($vNormString,$vCloseIndex+1))"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="tChopPunct">
                  <xsl:with-param name="pString" select="substring($vNormString,2)"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- special handling for period -->
          <!-- remove if there is other punctuation -->
          <xsl:when test="substring($vNormString,$vLength,1) = '.'">
            <xsl:choose>
              <xsl:when test="contains(concat($vPunct,$vEndEnclose),substring($vNormString,$vLength - 1,1))">
	              <xsl:call-template name="tChopPunct">
	                <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	              </xsl:call-template>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$vNormString"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="contains($vPunct, substring($vNormString,$vLength,1))">
	          <xsl:call-template name="tChopPunct">
	            <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	          </xsl:call-template>
          </xsl:when>
          <!-- remove end enclosing punctuation if start character is not in string -->
          <xsl:when test="substring($vNormString,$vLength,1)=')' and not(contains($vNormString,'('))">
	          <xsl:call-template name="tChopPunct">
	            <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	          </xsl:call-template>
          </xsl:when>
          <xsl:when test="substring($vNormString,$vLength,1)=']' and not(contains($vNormString,'['))">
	          <xsl:call-template name="tChopPunct">
	            <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	          </xsl:call-template>
          </xsl:when>
          <xsl:when test="substring($vNormString,$vLength,1)='}}' and not(contains($vNormString,'{{'))">
	          <xsl:call-template name="tChopPunct">
	            <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	          </xsl:call-template>
          </xsl:when>
          <xsl:when test="substring($vNormString,$vLength,1)='&quot;' and not(contains($vNormString,'&quot;'))">
	          <xsl:call-template name="tChopPunct">
	            <xsl:with-param name="pString" select="substring($vNormString,1,$vLength - 1)"/>
	          </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
	          <xsl:value-of select="$vNormString"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <xsl:template name="tLastIndex">
        <xsl:param name="pString"/>
        <xsl:param name="pSearch"/>
        <xsl:choose>
          <xsl:when test="$pSearch != '' and contains($pString,$pSearch)">
            <xsl:variable name="vRevSearch">
              <xsl:call-template name="tReverseString">
                <xsl:with-param name="pString" select="$pSearch"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="vRevString">
              <xsl:call-template name="tReverseString">
                <xsl:with-param name="pString" select="$pString"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="string-length($pString) - string-length(substring-before($vRevString,$vRevSearch))"/>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <xsl:template name="tReverseString">
        <xsl:param name="pString"/>
        <xsl:variable name="vLength" select="string-length($pString)"/>
        <xsl:choose>
          <xsl:when test="$vLength &lt; 2"><xsl:value-of select="$pString"/></xsl:when>
          <xsl:when test="$vLength = 2">
            <xsl:value-of select="concat(substring($pString,2,1),substring($pString,1,1))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="vMid" select="floor($vLength div 2)"/>
            <xsl:variable name="vHalf1">
              <xsl:call-template name="tReverseString">
                <xsl:with-param name="pString" select="substring($pString,1,$vMid)"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="vHalf2">
              <xsl:call-template name="tReverseString">
                <xsl:with-param name="pString" select="substring($pString,$vMid+1)"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="concat($vHalf2,$vHalf1)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <xsl:template name="tPadRight">
        <xsl:param name="pInput"/>
        <xsl:param name="pPadChar" select="' '"/>
        <xsl:param name="pStringLength" />
        <xsl:choose>
          <xsl:when test="string-length($pInput) &gt;= $pStringLength">
            <xsl:value-of select="$pInput"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="tPadRight">
              <xsl:with-param name="pInput" select="concat($pInput,$pPadChar)"/>
              <xsl:with-param name="pPadChar" select="$pPadChar"/>
              <xsl:with-param name="pStringLength" select="$pStringLength"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <xsl:template name="tPadLeft">
        <xsl:param name="pInput"/>
        <xsl:param name="pPadChar" select="' '"/>
        <xsl:param name="pStringLength" select="string-length($pInput)"/>
        <xsl:choose>
          <xsl:when test="string-length($pInput) &gt;= $pStringLength">
            <xsl:value-of select="$pInput"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="tPadLeft">
              <xsl:with-param name="pInput" select="concat($pPadChar,$pInput)"/>
              <xsl:with-param name="pPadChar" select="$pPadChar"/>
              <xsl:with-param name="pStringLength" select="$pStringLength"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- EDTF functions -->

      <!-- Extract first date from a range -->
      <xsl:template name="EDTF-Date1">
        <xsl:param name="pEDTFDate"/>
        <xsl:choose>
          <xsl:when test="contains($pEDTFDate,'/')">
            <xsl:value-of select="substring-before($pEDTFDate,'/')"/>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$pEDTFDate"/></xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- Extract second date from a range -->
      <xsl:template name="EDTF-Date2">
        <xsl:param name="pEDTFDate"/>
        <xsl:value-of select="substring-after($pEDTFDate,'/')"/>
      </xsl:template>

      <!-- Extract date part from a single EDTF date -->
      <!-- This will also work on ISO-8601 dates -->
      <xsl:template name="EDTF-DatePart">
        <xsl:param name="pEDTFDate"/>
        <xsl:choose>
          <xsl:when test="contains($pEDTFDate,'T')">
            <xsl:value-of select="substring-before($pEDTFDate,'T')"/>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$pEDTFDate"/></xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- Extract time part from a single EDTF date -->
      <!-- This will also work on ISO-8601 dates -->
      <xsl:template name="EDTF-TimePart">
        <xsl:param name="pEDTFDate"/>
        <xsl:choose>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'+')">
            <xsl:value-of select="substring-before(substring-after($pEDTFDate,'T'),'+')"/>
          </xsl:when>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'-')">
            <xsl:value-of select="substring-before(substring-after($pEDTFDate,'T'),'-')"/>
          </xsl:when>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'Z')">
            <xsl:value-of select="substring-before(substring-after($pEDTFDate,'T'),'Z')"/>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="substring-after($pEDTFDate,'T')"/></xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- Extract time differential from a single EDTF date -->
      <!-- This will also work on ISO-8601 dates -->
      <xsl:template name="EDTF-TimeDiff">
        <xsl:param name="pEDTFDate"/>
        <xsl:choose>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'+')">
            <xsl:value-of select="concat('+',substring-after(substring-after($pEDTFDate,'T'),'+'))"/>
          </xsl:when>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'-')">
            <xsl:value-of select="concat('-',substring-after(substring-after($pEDTFDate,'T'),'-'))"/>
          </xsl:when>
          <xsl:when test="contains(substring-after($pEDTFDate,'T'),'Z')">+00:00</xsl:when>
        </xsl:choose>
      </xsl:template>

      <!-- Translate EDTF Level 1 date to 033/263 format -->
      <!-- See https://www.loc.gov/standards/datetime/edtf.html -->
      <!-- Template expects single dates, not ranges (the 033 expresses ranges as multiple single dates) -->
      <xsl:template name="EDTF-to-033">
        <xsl:param name="pEDTFDate"/>

        <!-- Remove all qualifiers from EDTF date -->
        <xsl:variable name="vEDTFDate" select="translate(translate(translate($pEDTFDate,'?',''),'~',''),'%','')"/>

        <xsl:variable name="vDatePart">
          <xsl:call-template name="EDTF-DatePart">
            <xsl:with-param name="pEDTFDate" select="$vEDTFDate"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vTimePart">
          <xsl:call-template name="EDTF-TimePart">
            <xsl:with-param name="pEDTFDate" select="$vEDTFDate"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="vTimeDiffPart">
          <xsl:call-template name="EDTF-TimeDiff">
            <xsl:with-param name="pEDTFDate" select="$vEDTFDate"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="vYear">
          <!-- Translate 'X' to '-' -->
          <xsl:variable name="vYear033">
            <xsl:choose>
              <xsl:when test="contains($vDatePart,'-')">
                <xsl:value-of select="translate(substring-before($vDatePart,'-'),'X','-')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="translate($vDatePart,'X','-')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:choose>
            <!-- only support 4-digit, positive integer dates -->
            <xsl:when test="starts-with($vYear033,'Y') or starts-with($vYear033,'-') or (string-length($vYear033) != 4)">
              <xsl:text>----</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$vYear033"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vMonth">
          <!-- Translate 'X' to '-' -->
          <xsl:variable name="vMonth033">
            <xsl:choose>
              <xsl:when test="substring-after(substring-after($vDatePart,'-'),'-') != ''">
                <xsl:value-of select="translate(substring-before(substring-after($vDatePart,'-'),'-'),'X','-')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="translate(substring-after($vDatePart,'-'),'X','-')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:choose>
            <!-- only support 2-digit months up to 12 (no seasons) -->
            <xsl:when test="(string-length($vMonth033) != 2) or ($vMonth033 > 12)">
              <xsl:text>--</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$vMonth033"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vDay">
          <!-- Translate 'X' to '-' -->
          <xsl:variable name="vDay033" select="translate(substring-after(substring-after($vDatePart,'-'),'-'),'X','-')"/>
          <xsl:choose>
            <!-- only support 2-digit days up to 31 -->
            <xsl:when test="(string-length($vDay033) != 2) or ($vDay033 > 31)">
              <xsl:text>--</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$vDay033"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vTime">
          <xsl:if test="$vTimePart != ''">
            <!-- Translate 'X' to '-', remove colons -->
            <xsl:variable name="vTime033" select="translate(translate($vTimePart,'X','-'),':','')"/>
            <xsl:choose>
              <!-- only support 6-digits times (no other sanity check) -->
              <xsl:when test="string-length($vTime033) = 6"><xsl:value-of select="$vTime033"/></xsl:when>
              <xsl:otherwise>------</xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="vTimeDiff">
          <xsl:if test="($vTimePart != '') and ($vTimeDiffPart != '')">
            <!-- Translate 'X' to '-', remove colons -->
            <xsl:variable name="vTimeDiff033" select="translate(translate($vTimeDiffPart,'X','-'),':','')"/>
            <xsl:choose>
              <!-- Needs to be 5 characters, pad with zeros on the right -->
              <xsl:when test="string-length($vTimeDiff033) = 5"><xsl:value-of select="$vTimeDiff033"/></xsl:when>
              <xsl:when test="string-length($vTimeDiff033) = 3">
                <xsl:value-of select="concat($vTimeDiff033,'00')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:if>
        </xsl:variable>

        <xsl:value-of select="concat($vYear,$vMonth,$vDay,$vTime,$vTimeDiff)"/>
      </xsl:template>

      <!-- get the script code from an xml:lang attribute value -->
      <xsl:template name="tScriptCode">
        <xsl:param name="pXmlLang"/>
        <xsl:if test="string-length($pXmlLang) &gt;= 4">
          <xsl:choose>
            <xsl:when test="string-length($pXmlLang)=4 and translate(substring($pXmlLang,1,1),0123456789,'') != ''">
              <xsl:value-of select="$pXmlLang"/>
            </xsl:when>
              <xsl:when test="string-length(substring-before($pXmlLang,'-'))=4 and translate(substring($pXmlLang,1,1),0123456789,'') != ''">
              <xsl:value-of select="substring-before($pXmlLang,'-')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="tScriptCode">
                <xsl:with-param name="pXmlLang" select="substring-after($pXmlLang,'-')"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:template>

      <!-- get the code (last element) from a URI -->
      <xsl:template name="tUriCode">
        <xsl:param name="pUri"/>
        <xsl:choose>
          <xsl:when test="contains($pUri,'://')">
            <xsl:if test="contains(substring-after($pUri,'://'),'/')">
              <xsl:call-template name="tUriCode">
                <xsl:with-param name="pUri" select="substring-after($pUri,'://')"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:when>
          <xsl:when test="contains($pUri,'/')">
            <xsl:call-template name="tUriCode">
              <xsl:with-param name="pUri" select="substring-after($pUri,'/')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="contains($pUri,'?')">
                <xsl:value-of select="substring-before($pUri,'?')"/>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$pUri"/></xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- generate marc:subfields by tokenizing a string -->
      <xsl:template name="tToken2Subfields">
        <xsl:param name="pString"/>
        <xsl:param name="pSeparator" select="' '"/>
        <xsl:param name="pSubfieldCode"/>
        <xsl:choose>
          <xsl:when test="contains($pString,$pSeparator)">
            <marc:subfield>
              <xsl:attribute name="code"><xsl:value-of select="$pSubfieldCode"/></xsl:attribute>
              <xsl:value-of select="substring-before($pString,$pSeparator)"/>
            </marc:subfield>
            <xsl:call-template name="tToken2Subfields">
              <xsl:with-param name="pString" select="substring-after($pString,$pSeparator)"/>
              <xsl:with-param name="pSeparator" select="$pSeparator"/>
              <xsl:with-param name="pSubfieldCode" select="$pSubfieldCode"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <marc:subfield>
              <xsl:attribute name="code"><xsl:value-of select="$pSubfieldCode"/></xsl:attribute>
              <xsl:value-of select="$pString"/>
            </marc:subfield>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!-- get a MARC authority from a URI -->
      
      <xsl:template name="tGetRelResource">
        <xsl:param name="pRelUri"/>
        <xsl:param name="pContext"/>
        <xsl:choose>
          <xsl:when test="$pContext/marc:record">
            <xsl:copy-of select="$pContext/marc:record"/>
          </xsl:when>
          <xsl:when test="$pContext/bflc:marcKey">
            <marc:record>
              <marc:datafield>
                <xsl:attribute name="tag">
                  <xsl:choose>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '00'">100</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '10'">110</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '11'">111</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '30'">130</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '50'">150</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '51'">151</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 2, 2) = '55'">155</xsl:when>
                    <xsl:when test="substring($pContext/bflc:marcKey, 1, 3) = '440'">130</xsl:when>
                    <xsl:otherwise><xsl:value-of select="substring($pContext/bflc:marcKey, 1, 3)" /></xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="ind1">
                  <xsl:choose>
                    <xsl:when test="substring($pContext/bflc:marcKey, 1, 3) = 630 or substring($pContext/bflc:marcKey, 1, 3) = 730">
                      <!-- flipping to a 130 so we need to get non filing info into the right place. -->
                      <xsl:value-of select="substring($pContext/bflc:marcKey, 5, 1)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="substring($pContext/bflc:marcKey, 4, 1)" />    
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute> 
                <xsl:attribute name="ind2">
                  <xsl:choose>
                    <xsl:when test="substring($pContext/bflc:marcKey, 1, 3) = 630 or substring($pContext/bflc:marcKey, 1, 3) = 730">
                      <xsl:value-of select="substring($pContext/bflc:marcKey, 4, 1)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="substring($pContext/bflc:marcKey, 5, 1)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute> 
                <xsl:call-template name="tParseMarcKey">
                  <xsl:with-param name="pString" select="substring($pContext/bflc:marcKey, 6)" />
                </xsl:call-template>
              </marc:datafield>
            </marc:record>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="vRelResourcePreNS">
              <xsl:call-template name="tGetMARCAuth">
                <xsl:with-param name="pUri" select="$pRelUri"/>
              </xsl:call-template>          
            </xsl:variable>
            <!-- 
              In the interest of dashing future expectations, it is not possible
              to call exsl:node-set() at this juncture.  In XSLT 1.0 parlance, 
              templates return result tree fragments, which can only be used as 
              strings would be.  They need to be converted to node-sets downstream
              from here.
              See https://www.w3.org/TR/xslt-10/#section-Result-Tree-Fragments
              One might discover that Saxon and MarkLogic, and possibly other 
              processors, are forgiving of this rule, but then you will find out 
              that xsltproc is not.
            -->
            <xsl:copy-of select="$vRelResourcePreNS"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:template>

      <!--
          special handling for id.loc.gov authorities:
          Change the extension on the resource to .marcxml.xml UNLESS
          global variable pSRULookup is "true" (string eq), THEN
          convert id.loc.gov lookup to SRU search to get around
          limitations of libxslt web client. Can also force SRU
          lookup with template param pForceSRULookup (for testing)
      -->

      <xsl:template name="tGetMARCAuth">
        <xsl:param name="pUri"/>
        <xsl:param name="pForceSRULookup" select="false()"/>
        <xsl:variable name="vUrl">
          <xsl:choose>
            <xsl:when test="( 
                              contains($pUri,'id.loc.gov/authorities/') or 
                              contains($pUri,'id.loc.gov/rwo/agents') or 
                              contains($pUri,'id.loc.gov/resources/hubs') or 
                              contains($pUri,'id.worldcat.org/fast/') or 
                              contains($pUri,'d-nb.info/gnd/')
                            )
                            and not('.marcxml.xml' = substring($pUri, string-length($pUri) - 11))">
              <xsl:choose>
                <xsl:when test="($xslProcessor='libxslt' or $pSRULookup='true' or $pForceSRULookup=true())">
                  <xsl:variable name="vUriLccn">
                    <xsl:call-template name="tUriCode">
                      <xsl:with-param name="pUri" select="$pUri"/>
                    </xsl:call-template>
                  </xsl:variable>
                  <!-- need to distinguish between pre/post Y2K LCCNs -->
                  <xsl:variable name="vLccnSearch">
                    <xsl:variable name="vLccnNum">
                      <xsl:value-of select="translate($vUriLccn,translate($vUriLccn,'0123456789',''),'')"/>
                    </xsl:variable>
                    <xsl:variable name="vPrefix">
                      <xsl:value-of select="translate(substring($vUriLccn,1,3),'0123456789 ','')"/>
                    </xsl:variable>
                    <xsl:choose>
                      <!-- post Y2K -->
                      <xsl:when test="string-length($vLccnNum)=10">
                        <xsl:choose>
                          <xsl:when test="string-length($vPrefix) &lt; 2">
                            <xsl:value-of select="concat($vPrefix,'%20',$vLccnNum)"/>
                          </xsl:when>
                          <xsl:otherwise><xsl:value-of select="$vUriLccn"/></xsl:otherwise>
                        </xsl:choose>
                      </xsl:when>
                      <!-- pre Y2K -->
                      <xsl:otherwise>
                        <xsl:choose>
                          <xsl:when test="string-length($vPrefix) &lt; 3">
                            <xsl:value-of select="concat($vPrefix,'%20',$vLccnNum)"/>
                          </xsl:when>
                          <xsl:otherwise><xsl:value-of select="$vUriLccn"/></xsl:otherwise>
                        </xsl:choose>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="contains($pUri,'names') or contains($pUri,'agents')">
                      <xsl:value-of select="concat('http://lx2.loc.gov:210/NAF?query=bath.lccn%3d',$vLccnSearch,'&amp;recordSchema=marcxml&amp;maximumRecords=1')"/>
                    </xsl:when>
                    <xsl:when test="contains($pUri,'ubjects') or contains($pUri,'genreForm')">
                      <xsl:value-of select="concat('http://lx2.loc.gov:210/SAF?query=bath.lccn%3d',$vLccnSearch,'&amp;recordSchema=marcxml&amp;maximumRecords=1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:message>Desire to look up <xsl:value-of select="$pUri"/> but using xsltproc. No lookup occurred.</xsl:message>
                      <xsl:value-of select="$pUri"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="contains($pUri, 'id.worldcat.org/fast/')">
                  <xsl:variable name="vPath">
                    <xsl:value-of select="substring-after($pUri,'://id.worldcat.org')"/>
                  </xsl:variable>
                  <xsl:value-of select="concat('https://id.worldcat.org',$vPath,'.mrc.xml')"/>
                </xsl:when>
                <xsl:when test="contains($pUri, 'd-nb.info/gnd/')">
                  <xsl:variable name="vPath">
                    <xsl:value-of select="substring-after($pUri,'://d-nb.info')"/>
                  </xsl:variable>
                  <xsl:value-of select="concat('https://d-nb.info',$vPath,'/about/marcxml')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="vLookupURI">
                    <xsl:choose>
                      <xsl:when test="contains($pUri, 'id.loc.gov/rwo/agents')">
                        <xsl:value-of select="concat(substring-before($pUri,'rwo/agents'), 'authorities/names/', substring-after($pUri,'rwo/agents/'))"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$pUri"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="vPath">
                    <xsl:value-of select="substring-after($vLookupURI,'://id.loc.gov')"/>
                  </xsl:variable>
                  <xsl:value-of select="concat('https://id.loc.gov',$vPath,'.marcxml.xml')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$pUri"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$vUrl != '' and not($xslProcessor='libxslt' and contains($vUrl, 'resources/hubs'))">
            <xsl:variable name="vDoc">
              <xsl:choose>
                <xsl:when test="function-available('xdmp:document-get')">
                  <xsl:copy-of select="xdmp:document-get($vUrl)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:copy-of select="document($vUrl)" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <!-- <xsl:message><xsl:value-of select="$vUrl"/></xsl:message> -->
            <xsl:choose>
              <xsl:when test="$vDoc">
                <xsl:copy-of select="$vDoc"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- return empty collection so XSpec doesn't fail -->
                <marc:collection/>
              </xsl:otherwise>
            </xsl:choose>    
          </xsl:when>
          <xsl:otherwise>
            <!-- return empty collection so XSpec doesn't fail -->
            <marc:collection/>
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:template>
      
      <!--
        Special handling for label lookups at id.loc.gov
        Might have to do something like system-property('xsl:vendor') if HTTPS gives problems.
      -->
      <xsl:template name="tGetLabel">
        <xsl:param name="pUri"/>
        <xsl:if test="$xslProcessor != 'libxslt'">
        <xsl:variable name="vUrl">
          <xsl:choose>
            <xsl:when test="( 
              contains($pUri,'id.loc.gov/entities/') or 
              contains($pUri,'id.loc.gov/vocabulary/')
              )
              and not('.madsrdf_raw.rdf' = substring($pUri, string-length($pUri) - 16))">
              <xsl:variable name="vPath">
                <xsl:value-of select="substring-after($pUri,'://id.loc.gov')"/>
              </xsl:variable>
              <xsl:value-of select="concat('https://id.loc.gov',$vPath,'.madsrdf_raw.rdf')"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$pUri"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="vDoc">
          <xsl:choose>
            <xsl:when test="function-available('xdmp:document-get')">
              <xsl:copy-of select="xdmp:document-get($vUrl)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="document($vUrl)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$vDoc">
            <xsl:value-of select="$vDoc/rdf:RDF/madsrdf:*/madsrdf:authoritativeLabel[1]" />
          </xsl:when>
        </xsl:choose>
        </xsl:if>
      </xsl:template>
      
      <!-- generate marc:subfields by splitting a string with embedded subfields (i.e. bflc:readMarc382) -->
      <xsl:template name="tParseMarcKey">
        <xsl:param name="pString"/>
        <xsl:param name="pSeparator" select="'$'"/>
        <xsl:choose>
          <xsl:when test="starts-with($pString,$pSeparator)">
              <marc:subfield>
                <xsl:attribute name="code"><xsl:value-of select="substring(substring-after($pString,$pSeparator),1,1)"/></xsl:attribute>
                <xsl:choose>
                  <xsl:when test="contains(substring-after($pString,$pSeparator),$pSeparator)">
                    <xsl:value-of select="substring-before(substring(substring-after($pString,$pSeparator),2),$pSeparator)"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="substring(substring-after($pString,$pSeparator),2)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </marc:subfield>
            
            <xsl:choose>
              <xsl:when test="contains(substring-after($pString,$pSeparator),$pSeparator)">
                <xsl:call-template name="tParseMarcKey">
                  <xsl:with-param name="pString" select="concat($pSeparator,substring-after(substring-after($pString,$pSeparator),$pSeparator))"/>
                  <xsl:with-param name="pSeparator" select="$pSeparator"/>
                </xsl:call-template>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:template>

      <!-- generate marc:subfields by splitting a string with embedded subfields (i.e. bflc:readMarc382) -->
      <xsl:template name="tReadMarc382">
        <xsl:param name="pString"/>
        <xsl:param name="pSeparator" select="'$'"/>
        <xsl:choose>
          <xsl:when test="starts-with($pString,$pSeparator)">
            <!-- Do not generate $3, that should come from RDF -->
            <xsl:if test="substring(substring-after($pString,$pSeparator),1,1) != '3'">
              <marc:subfield>
                <xsl:attribute name="code"><xsl:value-of select="substring(substring-after($pString,$pSeparator),1,1)"/></xsl:attribute>
                <xsl:choose>
                  <xsl:when test="contains(substring-after($pString,$pSeparator),$pSeparator)">
                    <xsl:value-of select="substring-before(substring(substring-after($pString,$pSeparator),2),$pSeparator)"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="substring(substring-after($pString,$pSeparator),2)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </marc:subfield>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="contains(substring-after($pString,$pSeparator),$pSeparator)">
                <xsl:call-template name="tReadMarc382">
                  <xsl:with-param name="pString" select="concat($pSeparator,substring-after(substring-after($pString,$pSeparator),$pSeparator))"/>
                  <xsl:with-param name="pSeparator" select="$pSeparator"/>
                </xsl:call-template>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:template>

    </xsl:stylesheet>
  </xslt:template>

  <!-- top-level rules element -->
  <xslt:template match="bf2marc:rules">
    <xsl:variable name="vCurrentVersion"><xslt:value-of select="bf2marc:version"/></xsl:variable>

    <xslt:apply-templates mode="map"/>

    <xslt:apply-templates mode="key"/>

    <xsl:template match="/">

      <!-- rudimentary document validation -->
      <!-- Document should consist of an rdf:RDF root element with one top-level bf:Instance element -->
      <!-- There can be 0 or 1 top-level bf:Work element that is linked to the bf:Instance -->
      <xsl:choose>
        <xsl:when test="rdf:RDF">
          <xsl:choose>
            <xsl:when test="count(rdf:RDF/bf:Instance[not(rdf:type/@rdf:resource='http://id.loc.gov/ontologies/bflc/SecondaryInstance')]) = 1">
              <xsl:choose>
                <xsl:when test="count(rdf:RDF/bf:Work) = 0"/>
                <xsl:when test="count(rdf:RDF/bf:Work) = 1">
                  <xsl:choose>
                    <xsl:when test="rdf:RDF/bf:Instance/bf:instanceOf/bf:*[@rdf:about=/rdf:RDF/bf:Work/@rdf:about]"/>
                    <xsl:when test="rdf:RDF/bf:Instance/bf:instanceOf[@rdf:resource=/rdf:RDF/bf:Work/@rdf:about]"/>
                    <xsl:when test="rdf:RDF/bf:Work/bf:hasInstance[@rdf:resource=/rdf:RDF/bf:Instance/@rdf:about]"/>
                    <xsl:otherwise>
                      <xsl:message terminate="yes">Invalid document: top-level Instance and Work are not linked</xsl:message>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message terminate="yes">Invalid document: document can only have 0 or 1 top-level Work element</xsl:message>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="yes">Invalid document: document must have exactly one top-level Instance element</xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">Invalid document: no RDF root element</xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="rdf:RDF">
      <xsl:variable name="vPrincipalInstance" select="bf:Instance[not(rdf:type/@rdf:resource='http://id.loc.gov/ontologies/bflc/SecondaryInstance')]"/>
      <xsl:variable name="vAdminMetadata" select="$vPrincipalInstance/bf:adminMetadata/bf:AdminMetadata[1] | bf:Work/bf:adminMetadata/bf:AdminMetadata[not(/rdf:RDF/bf:Instance/bf:adminMetadata/bf:AdminMetadata)]"/>

      <xsl:variable name="vRecordId">
        <xsl:choose>
          <xsl:when test="$pRecordId = 'default'">
            <xsl:choose>
              <xsl:when test="$vAdminMetadata/bf:identifiedBy/bf:Local[not(bf:source) or bf:source/@rdf:resource='http://id.loc.gov/vocabulary/organizations/dlc' or bf:source/bf:Source/@rdf:about='http://id.loc.gov/vocabulary/organizations/dlc' or bf:source/bf:Source/rdfs:label='DLC']/rdf:value">
                <xsl:value-of select="$vAdminMetadata/bf:identifiedBy/bf:Local[not(bf:source) or bf:source/@rdf:resource='http://id.loc.gov/vocabulary/organizations/dlc' or bf:source/bf:Source/@rdf:about='http://id.loc.gov/vocabulary/organizations/dlc' or bf:source/bf:Source/rdfs:label='DLC']/rdf:value"/>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="generate-id()"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$pRecordId"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <marc:record> 
        <xslt:apply-templates mode="documentFrame"/>
      </marc:record>
    
    </xsl:template>

    <xslt:apply-templates mode="generateTemplates"/>

    <xsl:template match="text()"/>

  </xslt:template>

  <!-- templates for constructing map variables -->

  <!-- compile maps from included files -->
  <xslt:template match="bf2marc:file" mode="map">
    <xslt:apply-templates select="document(.)/bf2marc:rules/bf2marc:file | document(.)/bf2marc:rules/bf2marc:map" mode="map"/>
  </xslt:template>

  <xslt:template match="bf2marc:map" mode="map">
    <xsl:variable name="{@name}">
      <xslt:for-each select="*">
        <xslt:copy-of select="."/>
      </xslt:for-each>
    </xsl:variable>
  </xslt:template>

  <!-- templates for constructing keys: simple pass-through -->

  <!-- compile keys from included files -->
  <xslt:template match="bf2marc:file" mode="key">
    <xslt:apply-templates select="document(.)/bf2marc:rules/bf2marc:file | document(.)/bf2marc:rules/bf2marc:key" mode="key"/>
  </xslt:template>

  <xslt:template match="bf2marc:key" mode="key">
    <xsl:key name="{@name}" match="{@match}" use="{@use}"/>
  </xslt:template>

  <!-- templates for building the document frame -->

  <!-- compile rules from included files -->
  <xslt:template match="bf2marc:file" mode="documentFrame">
    <xslt:apply-templates select="document(.)/bf2marc:rules/bf2marc:file | document(.)/bf2marc:rules/bf2marc:cf | document(.)/bf2marc:rules/bf2marc:df | document(.)/bf2marc:rules/bf2marc:switch | document(.)/bf2marc:rules/bf2marc:select | document(.)/bf2marc:rules/bf2marc:transform | document(.)/bf2marc:rules/bf2marc:if" mode="documentFrame"/>
  </xslt:template>

  <xslt:template match="bf2marc:switch" mode="documentFrame">
    <xslt:apply-templates select="." mode="fieldTemplate"/>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="documentFrame">
    <xslt:apply-templates select="." mode="fieldTemplate"/>
  </xslt:template>

  <xslt:template match="bf2marc:transform" mode="documentFrame">
    <xslt:apply-templates select="." mode="fieldTemplate"/>
  </xslt:template>

  <xslt:template match="bf2marc:if" mode="documentFrame">
    <xsl:if test="{@test}">
      <xslt:apply-templates mode="documentFrame"/>
    </xsl:if>
  </xslt:template>

  <xslt:template match="bf2marc:cf|bf2marc:df" mode="documentFrame">
    <xslt:variable name="vRepeatable">
      <xslt:choose>
        <xslt:when test="local-name()='cf'">false</xslt:when>
        <xslt:otherwise><xslt:value-of select="@repeatable"/></xslt:otherwise>
      </xslt:choose>
    </xslt:variable>
    <xslt:variable name="vTagName">
      <xslt:value-of select="translate(@tag,'$','')"/>
    </xslt:variable>
    
    <xslt:choose>
      <xslt:when test="bf2marc:context">
        <xslt:choose>
          <!-- special handling for language preference/non-repeatable -->
          <!-- language handling relies on the script subtag being set in the xml:lang attribute -->
          <xslt:when test="@lang-prefer">
            <xslt:choose>
              <xslt:when test="@lang-xpath">
                <xslt:choose>
                  <xslt:when test="@lang-prefer='vernacular'">
                    <xsl:choose>
                      <xsl:when test="{bf2marc:context/@xpath}[{@lang-xpath}/@xml:lang and not(contains(translate({@lang-xpath}/@xml:lang,$upper,$lower),translate($pCatScript,$upper,$lower)))]">
                        <xsl:for-each select="{bf2marc:context/@xpath}[{@lang-xpath}/@xml:lang and not(contains(translate({@lang-xpath}/@xml:lang,$upper,$lower),translate($pCatScript,$upper,$lower)))]">
                          <xslt:apply-templates select="bf2marc:context/bf2marc:var" mode="fieldTemplate"/>
                          <xslt:choose>
                            <xslt:when test="$vRepeatable='false'">
                              <xsl:choose>
                                <xsl:when test="position()=1">
                                  <xslt:apply-templates select="." mode="fieldTemplate">
                                    <xslt:with-param name="repeatable" select="$vRepeatable"/>
                                  </xslt:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target field (<xslt:value-of select="$vTagName"/>).</xsl:message>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xslt:when>
                            <xslt:otherwise>
                              <xslt:apply-templates select="." mode="fieldTemplate">
                                <xslt:with-param name="repeatable" select="$vRepeatable"/>
                              </xslt:apply-templates>
                            </xslt:otherwise>
                          </xslt:choose>
                        </xsl:for-each>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:for-each select="{bf2marc:context/@xpath}">
                          <xslt:apply-templates select="bf2marc:context/bf2marc:var" mode="fieldTemplate"/>
                          <xslt:choose>
                            <xslt:when test="$vRepeatable='false'">
                              <xsl:choose>
                                <xsl:when test="position()=1">
                                  <xslt:apply-templates select="." mode="fieldTemplate">
                                    <xslt:with-param name="repeatable" select="$vRepeatable"/>
                                  </xslt:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target field (<xslt:value-of select="$vTagName"/>).</xsl:message>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xslt:when>
                            <xslt:otherwise>
                              <xslt:apply-templates select="." mode="fieldTemplate">
                                <xslt:with-param name="repeatable" select="$vRepeatable"/>
                              </xslt:apply-templates>
                            </xslt:otherwise>
                          </xslt:choose>
                        </xsl:for-each>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xslt:when>
                  <xslt:otherwise>
                    <xsl:choose>
                      <xsl:when test="{bf2marc:context/@xpath}[not({@lang-xpath}/@xml:lang) or contains(translate({@lang-xpath}/@xml:lang,$upper,$lower),translate($pCatScript,$upper,$lower))]">
                        <xsl:for-each select="{bf2marc:context/@xpath}[not({@lang-xpath}/@xml:lang) or contains(translate({@lang-xpath}/@xml:lang,$upper,$lower),translate($pCatScript,$upper,$lower))]">
                          <xslt:apply-templates select="bf2marc:context/bf2marc:var" mode="fieldTemplate"/>
                          <xslt:choose>
                            <xslt:when test="$vRepeatable='false'">
                              <xsl:choose>
                                <xsl:when test="position()=1">
                                  <xslt:apply-templates select="." mode="fieldTemplate">
                                    <xslt:with-param name="repeatable" select="$vRepeatable"/>
                                  </xslt:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target field (<xslt:value-of select="$vTagName"/>).</xsl:message>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xslt:when>
                            <xslt:otherwise>
                              <xslt:apply-templates select="." mode="fieldTemplate">
                                <xslt:with-param name="repeatable" select="$vRepeatable"/>
                              </xslt:apply-templates>
                            </xslt:otherwise>
                          </xslt:choose>
                        </xsl:for-each>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:for-each select="{bf2marc:context/@xpath}">
                          <xslt:apply-templates select="bf2marc:context/bf2marc:var" mode="fieldTemplate"/>
                          <xslt:choose>
                            <xslt:when test="$vRepeatable='false'">
                              <xsl:choose>
                                <xsl:when test="position()=1">
                                  <xslt:apply-templates select="." mode="fieldTemplate">
                                    <xslt:with-param name="repeatable" select="$vRepeatable"/>
                                  </xslt:apply-templates>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target field (<xslt:value-of select="$vTagName"/>).</xsl:message>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xslt:when>
                            <xslt:otherwise>
                              <xslt:apply-templates select="." mode="fieldTemplate">
                                <xslt:with-param name="repeatable" select="$vRepeatable"/>
                              </xslt:apply-templates>
                            </xslt:otherwise>
                          </xslt:choose>
                        </xsl:for-each>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xslt:otherwise>
                </xslt:choose>
              </xslt:when>
              <xslt:otherwise>
                <xslt:message terminate="yes">lang-prefer attribute used without lang-xpath in rule for tag <xslt:value-of select="@tag"/>.</xslt:message>
              </xslt:otherwise>
            </xslt:choose>
          </xslt:when>
          <xslt:otherwise>
            <xslt:for-each select="bf2marc:context">
              <xsl:apply-templates select="{@xpath}" mode="generate-{$vTagName}">
                <xsl:with-param name="vRecordId" select="$vRecordId"/>
                <xsl:with-param name="vAdminMetadata" select="$vAdminMetadata"/>
              </xsl:apply-templates>
            </xslt:for-each>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:when>
      <xslt:otherwise>
        <xslt:apply-templates select="." mode="fieldTemplate">
          <xslt:with-param name="repeatable" select="$vRepeatable"/>
        </xslt:apply-templates>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <!-- templates for generating templates -->

  <!-- compile rules from included files -->
  <xslt:template match="bf2marc:file" mode="generateTemplates">
    <xslt:apply-templates select="document(.)/bf2marc:rules/bf2marc:file | document(.)/bf2marc:rules/bf2marc:cf | document(.)/bf2marc:rules/bf2marc:df" mode="generateTemplates"/>
  </xslt:template>

  <xslt:template match="bf2marc:cf|bf2marc:df" mode="generateTemplates">
    <xslt:variable name="vTagName">
      <xslt:value-of select="translate(@tag,'$','')"/>
    </xslt:variable>
    <xslt:for-each select="bf2marc:context">
      <xslt:choose>
        <xslt:when test="(local-name(parent::*) = 'df' and parent::*/@repeatable != 'false') or
                         position() = 1">
          <xsl:template match="{@xpath}" mode="generate-{$vTagName}">
            <xsl:param name="vRecordId"/>
            <xsl:param name="vAdminMetadata"/>
            <xslt:apply-templates select="bf2marc:var" mode="fieldTemplate"/>
            <xslt:choose>
              <!-- Only when the 007 rule meets these conditions... -->
              <xslt:when test="local-name(parent::*)='cf' and $vTagName='007' and parent::*/@repeatable!=''">
                <xslt:apply-templates select="parent::*" mode="fieldTemplate">
                  <xslt:with-param name="repeatable"><xslt:value-of select="parent::*/@repeatable"/></xslt:with-param>
                </xslt:apply-templates>
              </xslt:when>
              <xslt:when test="local-name(parent::*) = 'cf' or parent::*/@repeatable = 'false'">
                <xsl:choose>
                  <xsl:when test="position() = 1">
                    <xslt:apply-templates select="parent::*" mode="fieldTemplate">
                      <xslt:with-param name="repeatable">false</xslt:with-param>
                    </xslt:apply-templates>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target field (<xslt:value-of select="$vTagName"/>).</xsl:message>
                  </xsl:otherwise>
                </xsl:choose>
              </xslt:when>
              <xslt:otherwise>
                <xslt:apply-templates select="parent::*" mode="fieldTemplate">
                  <xslt:with-param name="repeatable" select="parent::*/@repeatable"/>
                </xslt:apply-templates>
              </xslt:otherwise>
            </xslt:choose>
          </xsl:template>
        </xslt:when>
        <xslt:otherwise>
          <xslt:message terminate="yes">Multiple context blocks in non-repeatable field <xslt:value-of select="parent::*/@tag"/>.</xslt:message>
        </xslt:otherwise>
      </xslt:choose>
    </xslt:for-each>
  </xslt:template>

  <!-- frame for a MARC field -->
  <xslt:template match="bf2marc:cf|bf2marc:df" mode="fieldTemplate">
    <xslt:variable name="vFieldElement">
      <xslt:choose>
        <xslt:when test="@tag='LDR'">marc:leader</xslt:when>
        <xslt:when test="local-name()='cf'">marc:controlfield</xslt:when>
        <xslt:otherwise>marc:datafield</xslt:otherwise>
      </xslt:choose>
    </xslt:variable>
    <xslt:variable name="vRepeatable">
      <xslt:choose>
        <xslt:when test="local-name()='cf' and @repeatable!=''"><xslt:value-of select="@repeatable"/></xslt:when>
        <xslt:when test="local-name()='cf'">false</xslt:when>
        <xslt:otherwise><xslt:value-of select="@repeatable"/></xslt:otherwise>
      </xslt:choose>
    </xslt:variable>
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xslt:if test="@lang-xpath">
      <xsl:variable name="vXmlLang">
        <xsl:value-of select="{@lang-xpath}/@xml:lang"/>
      </xsl:variable>
    </xslt:if>
    <xslt:element name="{$vFieldElement}">
      <xslt:if test="@tag = 'LDR' or local-name()='cf'">
        <xsl:attribute name="xml:space">preserve</xsl:attribute>
      </xslt:if>
      <xslt:if test="@tag != 'LDR'">
        <xsl:attribute name="tag">
          <xslt:choose>
            <xslt:when test="starts-with(@tag,'$')">
              <xsl:value-of select="{@tag}"/>
            </xslt:when>
            <xslt:otherwise>
              <xslt:value-of select="@tag"/>
            </xslt:otherwise>
          </xslt:choose>
        </xsl:attribute>
        <xslt:if test="@tag = '010'">
          <xsl:attribute name="xml:space">preserve</xsl:attribute>
        </xslt:if>
        <xslt:if test="@lang-xpath">
          <xsl:if test="$vXmlLang != ''">
            <xsl:attribute name="xml:lang"><xsl:value-of select="$vXmlLang"/></xsl:attribute>
          </xsl:if>
        </xslt:if>
      </xslt:if>
      <xslt:choose>
        <xslt:when test="local-name()='cf' and $vConstant != ''">
          <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
        </xslt:when>
        <xslt:otherwise>
          <xslt:apply-templates mode="fieldTemplate">
            <xslt:with-param name="repeatable" select="$vRepeatable"/>
            <xslt:with-param name="pChopPunct" select="@chopPunct"/>
          </xslt:apply-templates>
        </xslt:otherwise>
      </xslt:choose>
    </xslt:element>
  </xslt:template>

  <!-- pass-through context elements, except for var elements -->
  <xslt:template match="bf2marc:context" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xslt:apply-templates mode="fieldTemplate" select="*[not(local-name()='var')]">
      <xslt:with-param name="repeatable" select="$repeatable"/>
      <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
    </xslt:apply-templates>
  </xslt:template>

  <!-- additional framing for MARC data fields -->
  <xslt:template match="bf2marc:ind1|bf2marc:ind2" mode="fieldTemplate">
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xsl:attribute name="{local-name()}">
      <xslt:choose>
        <xslt:when test="$vConstant = ''">
          <xslt:choose>
            <xslt:when test="child::*">
              <xsl:variable name="vInd">
                <xslt:apply-templates mode="fieldTemplate">
                  <xslt:with-param name="repeatable">false</xslt:with-param>
                </xslt:apply-templates>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$vInd != ''"><xsl:value-of select="$vInd"/></xsl:when>
                <xsl:otherwise>
                  <xsl:text><xslt:value-of select="@default"/></xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xslt:when>
            <xslt:otherwise>
              <xsl:text><xslt:value-of select="@default"/></xsl:text>
            </xslt:otherwise>
          </xslt:choose>
        </xslt:when>
        <xslt:otherwise>
          <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
        </xslt:otherwise>
      </xslt:choose>
    </xsl:attribute>
  </xslt:template>

  <xslt:template match="bf2marc:sf" mode="fieldTemplate">
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xslt:variable name="vTagName">
      <xslt:value-of select="translate(ancestor::*/@tag,'$','')"/>
    </xslt:variable>
    <xslt:choose>
      <xslt:when test="$vConstant != ''">
        <marc:subfield code="{@code}"><xslt:value-of select="$vConstant"/></marc:subfield>
      </xslt:when>
      <xslt:when test="bf2marc:select">
        <xslt:apply-templates select="bf2marc:select" mode="fieldTemplate">
          <xslt:with-param name="repeatable" select="@repeatable"/>
          <xslt:with-param name="pChopPunct" select="@chopPunct"/>
        </xslt:apply-templates>
      </xslt:when>
      <xslt:otherwise>
        <xsl:variable name="v{$vTagName}-{@code}">
          <xslt:apply-templates mode="fieldTemplate">
            <xslt:with-param name="repeatable" select="@repeatable"/>
            <xslt:with-param name="pChopPunct" select="@chopPunct"/>
          </xslt:apply-templates>
        </xsl:variable>
        <xsl:if test="$v{$vTagName}-{@code} != ''">
          <marc:subfield code="{@code}">
            <xsl:value-of select="$v{$vTagName}-{@code}"/>
          </marc:subfield>
        </xsl:if>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xslt:choose>
      <xslt:when test="@xpath='.'">
        <xslt:apply-templates select="." mode="outerXSL">
          <xslt:with-param name="repeatable" select="$repeatable"/>
          <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
        </xslt:apply-templates>
      </xslt:when>
      <xslt:otherwise>
        <xslt:choose>
          <xslt:when test="position() = 1 or $repeatable != 'false'">
            <xsl:for-each select="{@xpath}">
              <xslt:choose>
                <xslt:when test="$repeatable = 'false'">
                  <xsl:choose>
                    <xsl:when test="position() = 1">
                      <xslt:apply-templates select="." mode="outerXSL">
                        <xslt:with-param name="repeatable" select="$repeatable"/>
                        <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
                      </xslt:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:message>Record <xsl:value-of select="$vRecordId"/>: Unprocessed node <xsl:value-of select="name()"/>. Non-repeatable target element <xslt:value-of select="translate(ancestor::*/@tag,'$','')"/><xslt:if test="ancestor::bf2marc:sf"> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xslt:if>.</xsl:message>
                    </xsl:otherwise>
                  </xsl:choose>
                </xslt:when>
                <xslt:otherwise>
                  <xslt:apply-templates select="." mode="outerXSL">
                    <xslt:with-param name="repeatable" select="$repeatable"/>
                    <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
                  </xslt:apply-templates>
                </xslt:otherwise>
              </xslt:choose>
            </xsl:for-each>
          </xslt:when>
          <xslt:otherwise>
            <xslt:message terminate="yes">
              <xslt:text>Multiple select blocks in non-repeatable target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/> <xslt:if test="ancestor::bf2marc:sf">$<xslt:value-of select="parent::bf2marc:sf/@code"/>.</xslt:if><xslt:text> position=</xslt:text><xslt:value-of select="position()"/>
            </xslt:message>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="outerXSL">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xslt:choose>
      <xslt:when test="local-name(parent::*)='sf'">
        <marc:subfield code="{parent::bf2marc:sf/@code}">
          <xslt:apply-templates select="." mode="innerXSL">
            <xslt:with-param name="repeatable" select="$repeatable"/>
            <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
          </xslt:apply-templates>
        </marc:subfield>
      </xslt:when>
      <xslt:otherwise>
        <xslt:apply-templates select="." mode="innerXSL">
          <xslt:with-param name="repeatable" select="$repeatable"/>
          <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
        </xslt:apply-templates>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="innerXSL">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xslt:choose>
      <xslt:when test="$vConstant != ''">
        <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
      </xslt:when>
      <xslt:when test="child::*">
        <xslt:apply-templates mode="fieldTemplate">
          <xslt:with-param name="repeatable" select="$repeatable"/>
          <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
        </xslt:apply-templates>
      </xslt:when>
      <xslt:otherwise>
        <xslt:choose>
          <xslt:when test="$pChopPunct = 'true'">
            <xsl:call-template name="tChopPunct">
              <xsl:with-param name="pString" select="."/>
            </xsl:call-template>
          </xslt:when>
          <xslt:otherwise>
            <xsl:value-of select="."/>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:switch" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xsl:choose>
      <xslt:for-each select="bf2marc:case[@test != 'default']">
        <xsl:when test="{@test}">
          <xslt:apply-templates select="." mode="innerXSL">
            <xslt:with-param name="repeatable" select="$repeatable"/>
            <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
          </xslt:apply-templates>
        </xsl:when>
      </xslt:for-each>
      <xslt:for-each select="bf2marc:case[@test='default']">
        <xslt:choose>
          <xslt:when test="position() = 1">
            <xsl:otherwise>
              <xslt:apply-templates select="." mode="innerXSL">
                <xslt:with-param name="repeatable" select="$repeatable"/>
                <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
              </xslt:apply-templates>
            </xsl:otherwise>
          </xslt:when>
          <xslt:otherwise>
            <xslt:message terminate="yes">
              <xslt:text>Multiple default cases in switch block for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/> <xslt:if test="ancestor::bf2marc:sf/@code">$<xslt:value-of select="ancestor::bf2marc:sf/@code"/>.</xslt:if>
            </xslt:message>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:for-each>
    </xsl:choose>
  </xslt:template>

  <xslt:template match="bf2marc:case" mode="innerXSL">
    <xslt:param name="repeatable"/>
    <xslt:param name="pChopPunct"/>
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xslt:choose>
      <xslt:when test="$vConstant != ''">
        <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
      </xslt:when>
      <xslt:otherwise>
        <xslt:apply-templates mode="fieldTemplate">
          <xslt:with-param name="repeatable">
            <xslt:choose>
              <xslt:when test="ancestor::bf2marc:sf">false</xslt:when>
              <xslt:otherwise><xslt:value-of select="$repeatable"/></xslt:otherwise>
            </xslt:choose>
          </xslt:with-param>
          <xslt:with-param name="pChopPunct" select="$pChopPunct"/>
        </xslt:apply-templates>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:fixed-field" mode="fieldTemplate">
    <xslt:choose>
      <xslt:when test="position() = 1">
        <xslt:for-each select="bf2marc:position">
          <xslt:variable name="vConstant">
            <xslt:for-each select="text()|bf2marc:text">
              <xslt:value-of select="."/>
            </xslt:for-each>
          </xslt:variable>
          <xslt:choose>
            <xslt:when test="$vConstant = ''">
              <xslt:choose>
                <xslt:when test="child::*">
                  <xsl:variable name="vPosition-{position()}">
                    <xslt:apply-templates mode="fieldTemplate" select="child::*">
                      <xslt:with-param name="repeatable">false</xslt:with-param>
                    </xslt:apply-templates>
                  </xsl:variable>
                  <xsl:choose>
                    <xsl:when test="$vPosition-{position()} != ''">
                      <xsl:value-of select="$vPosition-{position()}"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text><xslt:value-of select="@default"/></xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xslt:when>
                <xslt:otherwise>
                  <xsl:text><xslt:value-of select="@default"/></xsl:text>
                </xslt:otherwise>
              </xslt:choose>
            </xslt:when>
            <xslt:otherwise>
              <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
            </xslt:otherwise>
          </xslt:choose>
        </xslt:for-each>
      </xslt:when>
      <xslt:otherwise>
        <xslt:message terminate="yes">
          <xslt:text>Multiple fixed-field blocks for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/> <xslt:if test="ancestor::bf2marc:sf">$<xslt:value-of select="ancestor::bf2marc:sf/@code"/>.</xslt:if>
        </xslt:message>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:lookup" mode="fieldTemplate">
    <xslt:choose>
      <xslt:when test="@map != '' and @targetField != '' and count(bf2marc:lookupField) &gt; 0">
        <xslt:variable name="vConditions">
          <xslt:for-each select="bf2marc:lookupField">
            <xslt:choose>
              <xslt:when test="@name != ''">
                <xslt:variable name="vCondition">
                  <xslt:choose>
                    <xslt:when test="@xpath != ''">
                      <xslt:value-of select="@name"/>=$v<xslt:value-of select="@name"/>
                    </xslt:when>
                    <xslt:otherwise>
                      <xslt:value-of select="@name"/>='<xslt:value-of select="text()"/><xslt:text>'</xslt:text>
                    </xslt:otherwise>
                  </xslt:choose>
                </xslt:variable>
                <xslt:choose>
                  <xslt:when test="position() = 1"><xslt:value-of select="$vCondition"/></xslt:when>
                  <xslt:otherwise> and <xslt:value-of select="$vCondition"/></xslt:otherwise>
                </xslt:choose>
              </xslt:when>
              <xslt:otherwise>
                <xslt:message terminate="yes">
                  <xslt:text>Invalid lookupField rule for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/><xslt:if test="ancestor::bf2marc:sf"> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xslt:if><xslt:text>. No name attribute.</xslt:text>
                </xslt:message>
              </xslt:otherwise>
            </xslt:choose>
          </xslt:for-each>
        </xslt:variable>
        <xslt:for-each select="bf2marc:lookupField">
          <xslt:if test="@xpath != ''">
            <xsl:variable name="{concat('v',@name)}">
              <xsl:value-of select="{@xpath}"/>
            </xsl:variable>
          </xslt:if>
        </xslt:for-each>
        <xslt:choose>
          <xslt:when test="local-name(parent::*)='sf'">
            <marc:subfield code="{parent::bf2marc:sf/@code}">
              <xsl:value-of select="{concat('exsl:node-set($',@map,')/*[',$vConditions,']/',@targetField)}"/>
            </marc:subfield>
          </xslt:when>
          <xslt:otherwise>
            <xsl:value-of select="{concat('exsl:node-set($',@map,')/*[',$vConditions,']/',@targetField)}"/>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:when>
      <xslt:otherwise>
        <xslt:choose>
          <xslt:when test="@map = ''">
            <xslt:message terminate="yes">
              <xslt:text>Invalid lookup rule for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/><xslt:if test="ancestor::bf2marc:sf"> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xslt:if><xslt:text>. No map attribute.</xslt:text>
            </xslt:message>
          </xslt:when>
          <xslt:when test="@targetField = ''">
            <xslt:message terminate="yes">
              <xslt:text>Invalid lookupField rule for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/><xslt:if test="ancestor::bf2marc:sf"> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xslt:if><xslt:text>. No targetField attribute.</xslt:text>
            </xslt:message>
          </xslt:when>
          <xslt:otherwise>
            <xslt:message terminate="yes">
              <xslt:text>Invalid lookup rule for target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/><xslt:if test="ancestor::bf2marc:sf"> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xslt:if><xslt:text>. No lookupField elements.</xslt:text>
            </xslt:message>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:var" mode="fieldTemplate">
    <xslt:choose>
      <xslt:when test="@xpath">
        <xsl:variable name="{@name}" select="{@xpath}"/>
      </xslt:when>
      <xslt:otherwise>
        <xsl:variable name="{@name}">
          <xslt:apply-templates mode="fieldTemplate" select="bf2marc:switch|bf2marc:transform|bf2marc:lookup"/>
        </xsl:variable>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:transform" mode="fieldTemplate">
    <xslt:apply-templates mode="copy"/>
  </xslt:template>

  <!-- recursive templates to copy nodes -->
  <xslt:template match="*" mode="copy">
    <xslt:element name="{name()}" namespace="{namespace-uri()}">
      <xslt:apply-templates select="@*|node()" mode="copy" />
    </xslt:element>
  </xslt:template>

  <xslt:template match="@*|text()|comment()" mode="copy">
    <xslt:copy/>
  </xslt:template>

  <!-- suppress text from unmatched nodes -->
  <xslt:template match="text()" mode="map"/>
  <xslt:template match="text()" mode="key"/>
  <xslt:template match="text()" mode="documentFrame"/>
  <xslt:template match="text()" mode="generateTemplates"/>
  <xslt:template match="text()" mode="fieldTemplate"/>

</xslt:stylesheet>
