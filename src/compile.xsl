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
                 exclude-result-prefixes="bf2marc">

  <xslt:namespace-alias stylesheet-prefix="xsl" result-prefix="xslt"/>
  <xslt:output encoding="UTF-8" method="xml" indent="yes"/>
  <xslt:preserve-space elements="bf2marc:text"/>
  <xslt:strip-space elements="*"/>

  <xslt:template match="/">
    <xsl:stylesheet version="1.0"
                    xmlns:date="http://exslt.org/dates-and-times"
                    extension-element-prefixes="date"
                    exclude-result-prefixes="rdf rdfs bf bflc madsrdf">

      <xsl:output encoding="UTF-8" method="xml" indent="yes"/>
      <xsl:strip-space elements="*"/>

      <xsl:param name="pRecordId" select="generate-id()"/>

      <xsl:variable name="vRecordId">
        <xsl:choose>
          <xsl:when test="$pRecordId = generate-id()">
            <xsl:choose>
              <xsl:when test="/rdf:RDF/bf:Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local[not(bf:source) or bf:source/bf:Source/rdfs:label='DLC']/rdf:value">
                <xsl:value-of select="/rdf:RDF/bf:Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local[not(bf:source) or bf:source/bf:Source/rdfs:label='DLC']/rdf:value"/>
              </xsl:when>
              <xsl:otherwise><xsl:value-of select="$pRecordId"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$pRecordId"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:param name="pGenerationDatestamp">
        <xsl:if test="function-available('date:date-time')">
          <xsl:value-of select="date:date-time()"/>
        </xsl:if>
      </xsl:param>

      <xslt:apply-templates/>

      <!-- Conversion functions -->

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

    </xsl:stylesheet>
  </xslt:template>

  <!-- top-level rules element -->
  <xslt:template match="bf2marc:rules">
    <xsl:variable name="vCurrentVersion"><xslt:value-of select="bf2marc:version"/></xsl:variable>

    <xsl:template match="/">
      <marc:record>

        <xslt:apply-templates mode="documentFrame"/>

      </marc:record>
    </xsl:template>

    <xslt:apply-templates mode="generateTemplates"/>

    <xsl:template match="text()"/>

  </xslt:template>

  <!-- templates for building the document frame -->

  <!-- compile rules from included files -->
  <xslt:template match="bf2marc:file" mode="documentFrame">
    <xslt:apply-templates select="document(.)/bf2marc:rules/bf2marc:file | document(.)/bf2marc:rules/bf2marc:cf | document(.)/bf2marc:rules/bf2marc:df" mode="documentFrame"/>
  </xslt:template>

  <xslt:template match="bf2marc:cf|bf2marc:df" mode="documentFrame">
    <xslt:variable name="vRepeatable">
      <xslt:choose>
        <xslt:when test="local-name()='cf'">false</xslt:when>
        <xslt:otherwise><xslt:value-of select="@repeatable"/></xslt:otherwise>
      </xslt:choose>
    </xslt:variable>
    <xslt:choose>
      <xslt:when test="bf2marc:context">
        <xslt:for-each select="bf2marc:context">
          <xsl:apply-templates select="{@xpath}" mode="generate-{parent::*/@tag}"/>
        </xslt:for-each>
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
    <xslt:for-each select="bf2marc:context">
      <xslt:choose>
        <xslt:when test="(local-name(parent::*) = 'df' and parent::*/@repeatable != 'false') or
                         position() = 1">
          <xsl:template match="{@xpath}" mode="generate-{parent::*/@tag}">
            <xslt:choose>
              <xslt:when test="local-name(parent::*) = 'cf' or parent::*/@repeatable = 'false'">
                <xsl:choose>
                  <xsl:when test="position() = 1">
                    <xslt:apply-templates select="parent::*" mode="fieldTemplate">
                      <xslt:with-param name="repeatable">false</xslt:with-param>
                    </xslt:apply-templates>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:message>
                      <xsl:text>Record </xsl:text>
                      <xsl:value-of select="$vRecordId"/>
                      <xsl:text>: Unprocessed node </xsl:text>
                      <xsl:value-of select="name()"/>
                      <xsl:text>. Non-repeatable target field (</xsl:text>
                      <xslt:value-of select="parent::*/@tag"/>
                      <xsl:text>).</xsl:text>
                    </xsl:message>
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
        <xslt:when test="local-name()='cf'">false</xslt:when>
        <xslt:otherwise><xslt:value-of select="@repeatable"/></xslt:otherwise>
      </xslt:choose>
    </xslt:variable>
    <xslt:variable name="vConstant">
      <xslt:for-each select="text()|bf2marc:text">
        <xslt:value-of select="."/>
      </xslt:for-each>
    </xslt:variable>
    <xslt:element name="{$vFieldElement}">
      <xslt:if test="@tag != 'LDR'">
        <xsl:attribute name="tag"><xslt:value-of select="@tag"/></xsl:attribute>
      </xslt:if>
      <xslt:choose>
        <xslt:when test="local-name()='cf' and $vConstant != ''">
          <xsl:text><xslt:value-of select="$vConstant"/></xsl:text>
        </xslt:when>
        <xslt:otherwise>
          <xslt:apply-templates mode="fieldTemplate">
            <xslt:with-param name="repeatable" select="$vRepeatable"/>
          </xslt:apply-templates>
        </xslt:otherwise>
      </xslt:choose>
    </xslt:element>
  </xslt:template>

  <!-- pass-through context elements -->
  <xslt:template match="bf2marc:context" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xslt:apply-templates mode="fieldTemplate">
      <xslt:with-param name="repeatable" select="$repeatable"/>
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
    <xslt:choose>
      <xslt:when test="$vConstant != ''">
        <marc:subfield code="{@code}"><xslt:value-of select="$vConstant"/></marc:subfield>
      </xslt:when>
      <xslt:when test="bf2marc:select">
        <xslt:apply-templates select="bf2marc:select" mode="fieldTemplate">
          <xslt:with-param name="repeatable" select="@repeatable"/>
        </xslt:apply-templates>
      </xslt:when>
      <xslt:otherwise>
        <xsl:variable name="v{ancestor::*/@tag}-{@code}">
          <xslt:apply-templates mode="fieldTemplate">
            <xslt:with-param name="repeatable" select="@repeatable"/>
          </xslt:apply-templates>
        </xsl:variable>
        <xsl:if test="$v{ancestor::*/@tag}-{@code} != ''">
          <marc:subfield code="{@code}">
            <xsl:value-of select="$v{ancestor::*/@tag}-{@code}"/>
          </marc:subfield>
        </xsl:if>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xslt:choose>
      <xslt:when test="@xpath='.'">
        <xslt:apply-templates select="." mode="outerXSL">
          <xslt:with-param name="repeatable" select="$repeatable"/>
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
                      </xslt:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:message terminate="no">
                        <xsl:text>Record </xsl:text>
                        <xsl:value-of select="$vRecordId"/>
                        <xsl:text>: Unprocessed node </xsl:text>
                        <xsl:value-of select="name()"/>
                        <xsl:text>. Non-repeatable target element <xslt:value-of select="ancestor::*/@tag"/></xsl:text>
                        <xslt:if test="ancestor::bf2marc:sf">
                          <xsl:text> $<xslt:value-of select="ancestor::bf2marc:sf/@code"/></xsl:text>
                        </xslt:if>
                      </xsl:message>
                    </xsl:otherwise>
                  </xsl:choose>
                </xslt:when>
                <xslt:otherwise>
                  <xslt:apply-templates select="." mode="outerXSL">
                    <xslt:with-param name="repeatable" select="$repeatable"/>
                  </xslt:apply-templates>
                </xslt:otherwise>
              </xslt:choose>
            </xsl:for-each>
          </xslt:when>
          <xslt:otherwise>
            <xslt:message terminate="yes">
              <xslt:text>Multiple select blocks in non-repeatable target element </xslt:text><xslt:value-of select="ancestor::*/@tag"/> <xslt:if test="ancestor::bf2marc:sf">$<xslt:value-of select="parent::bf2marc:sf/@code"/>.</xslt:if>
            </xslt:message>
          </xslt:otherwise>
        </xslt:choose>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="outerXSL">
    <xslt:param name="repeatable"/>
    <xslt:choose>
      <xslt:when test="local-name(parent::*)='sf'">
        <marc:subfield code="{parent::bf2marc:sf/@code}">
          <xslt:apply-templates select="." mode="innerXSL">
            <xslt:with-param name="repeatable" select="$repeatable"/>
          </xslt:apply-templates>
        </marc:subfield>
      </xslt:when>
      <xslt:otherwise>
        <xslt:apply-templates select="." mode="innerXSL">
          <xslt:with-param name="repeatable" select="$repeatable"/>
        </xslt:apply-templates>
      </xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:select" mode="innerXSL">
    <xslt:param name="repeatable"/>
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
        </xslt:apply-templates>
      </xslt:when>
      <xslt:otherwise><xsl:value-of select="."/></xslt:otherwise>
    </xslt:choose>
  </xslt:template>

  <xslt:template match="bf2marc:switch" mode="fieldTemplate">
    <xslt:param name="repeatable"/>
    <xsl:choose>
      <xslt:for-each select="bf2marc:case[@test != 'default']">
        <xsl:when test="{@test}">
          <xslt:apply-templates select="." mode="innerXSL">
            <xslt:with-param name="repeatable" select="$repeatable"/>
          </xslt:apply-templates>
        </xsl:when>
      </xslt:for-each>
      <xslt:for-each select="bf2marc:case[@test='default']">
        <xslt:choose>
          <xslt:when test="position() = 1">
            <xsl:otherwise>
              <xslt:apply-templates select="." mode="innerXSL">
                <xslt:with-param name="repeatable" select="$repeatable"/>
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
          <xslt:with-param name="repeatable" select="$repeatable"/>
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
                    <xslt:apply-templates mode="fieldTemplate">
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
  <xslt:template match="text()" mode="documentFrame"/>
  <xslt:template match="text()" mode="generateTemplates"/>
  <xslt:template match="text()" mode="fieldTemplate"/>

</xslt:stylesheet>
