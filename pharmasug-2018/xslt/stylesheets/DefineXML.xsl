<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:odm="http://www.cdisc.org/ns/odm/v1.3"
  xmlns:def="http://www.cdisc.org/ns/def/v2.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:arm="http://www.cdisc.org/ns/arm/v1.0">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  
  <xsl:variable name="ODM" select="/odm:ODM"/>
  <xsl:variable name="Study" select="$ODM/odm:Study"/>
  <xsl:variable name="MetaDataVersion" select="$Study/odm:MetaDataVersion"/>
  <xsl:variable name="ItemGroupDefs" select="$MetaDataVersion/odm:ItemGroupDef"/>
  <xsl:variable name="ItemDefs" select="$MetaDataVersion/odm:ItemDef"/>
  <xsl:variable name="MethodDefs" select="$MetaDataVersion/odm:MethodDef"/>
  <xsl:variable name="CommentDefs" select="$MetaDataVersion/def:CommentDef"/>
  
  <xsl:template match="odm:ODM">
    <xsl:element name="LIBRARY">
      <xsl:call-template name="ItemGroupDef"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template name="ItemGroupDef">
    
    <xsl:for-each select="//odm:ItemGroupDef">
      
      <xsl:variable name="ArchiveLocationID" select="@def:ArchiveLocationID"/>
      <xsl:variable name="CommentOID" select="@def:CommentOID"/>
      
      <xsl:variable name="KeySequence" select="odm:ItemRef/@KeySequence"/>
      <xsl:variable name="n_keys" select="count($KeySequence)"/>
      <xsl:variable name="keys" >
        <xsl:for-each select="odm:ItemRef">
          <xsl:sort select="@KeySequence" data-type="number" order="ascending"/>
          <xsl:if test="@KeySequence[ .!='' ]">
            <xsl:variable name="ItemOID" select="@ItemOID"/>
            <xsl:variable name="Name" select="$ItemDefs[@OID=$ItemOID]"/>
            <xsl:value-of select="$Name/@Name"/>
            <xsl:if test="@KeySequence &lt; $n_keys"><xsl:text> </xsl:text></xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      
      <xsl:element name="ItemGroupDef">
        <xsl:element name="table"><xsl:value-of select="@Name"/></xsl:element>
        <xsl:element name="label"><xsl:value-of select="odm:Description/odm:TranslatedText/text()"/></xsl:element>
        <xsl:element name="order"><xsl:value-of select="position()"/></xsl:element>
        <xsl:element name="repeating"><xsl:value-of select="@Repeating"/></xsl:element>
        <xsl:element name="isreferencedata"><xsl:value-of select="@IsReferenceData"/></xsl:element>
        <xsl:element name="domain"><xsl:value-of select="@Domain"/></xsl:element>
        <xsl:element name="domaindescription"><xsl:value-of select="odm:Alias[@Context='DomainDescription']/@Name"/></xsl:element>
        <xsl:element name="class"><xsl:value-of select="@def:Class"/></xsl:element>
        <xsl:element name="xmlpath"><xsl:value-of select="def:leaf[@ID = $ArchiveLocationID]/@xlink:href"/></xsl:element>
        <xsl:element name="xmltitle"><xsl:value-of select="def:leaf[@ID = $ArchiveLocationID]/def:title/text()"/></xsl:element>
        <xsl:element name="structure"><xsl:value-of select="@def:Structure"/></xsl:element>
        <xsl:element name="purpose"><xsl:value-of select="@Purpose"/></xsl:element>
        <xsl:element name="keys"><xsl:value-of select="$keys"/></xsl:element>
        <xsl:element name="date"><xsl:value-of select="substring($ODM/@CreationDateTime, 1, 10)"/></xsl:element>
        <xsl:element name="comment"><xsl:value-of select="$CommentDefs[@OID = $CommentOID]/odm:Description/odm:TranslatedText/text()"/></xsl:element>
        <xsl:element name="studyversion"><xsl:value-of select="$MetaDataVersion/@OID"/></xsl:element>
        <xsl:element name="standard"><xsl:value-of select="$MetaDataVersion/@def:StandardName"/></xsl:element>
        <xsl:element name="standardversion"><xsl:value-of select="$MetaDataVersion/@def:StandardVersion"/></xsl:element>
      </xsl:element>
      
      <xsl:for-each select="odm:ItemRef">
        <xsl:call-template name="ItemRefItemDef"/>
      </xsl:for-each>
      
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="ItemRefItemDef">
    <xsl:for-each select=".">
      
      <xsl:variable name="ItemOID" select="@ItemOID"/>
      <xsl:variable name="ItemDef" select="$ItemDefs[@OID = $ItemOID]"/>
      <xsl:variable name="MethodOID" select="@MethodOID"/>
      <xsl:variable name="CommentOID" select="$ItemDef/@def:CommentOID"/>
      
      <xsl:element name="ItemRefItemDef">
        <xsl:element name="table"><xsl:value-of select="../@Name"/></xsl:element>
        <xsl:element name="column"><xsl:value-of select="$ItemDef/@Name"/></xsl:element>
        <xsl:element name="label">
          <xsl:value-of select="$ItemDef/odm:Description/odm:TranslatedText/text()"/>
        </xsl:element>
        <xsl:element name="order"><xsl:value-of select="@OrderNumber"/></xsl:element>
        <xsl:element name="length"><xsl:value-of select="$ItemDef/@Length"/></xsl:element>
        <xsl:element name="displayformat"><xsl:value-of select="$ItemDef/@def:DisplayFormat"/></xsl:element>
        <xsl:element name="significantdigits"><xsl:value-of select="$ItemDef/@SignificantDigits"/></xsl:element>
        <xsl:element name="xmldatatype"><xsl:value-of select="$ItemDef/@DataType"/></xsl:element>
        <xsl:element name="xmlcodelist"><xsl:value-of select="$ItemDef/odm:CodeListRef/@CodeListOID"/></xsl:element>
        <xsl:element name="origin"><xsl:value-of select="$ItemDef/def:Origin/@Type"/></xsl:element>
        <xsl:element name="origindescription">
          <xsl:value-of select="$ItemDef/def:Origin/odm:Description/odm:TranslatedText/text()"/>
        </xsl:element>
        <xsl:element name="role"><xsl:value-of select="@Role"/></xsl:element>
        <xsl:element name="algorithm">
          <xsl:value-of select="$MethodDefs[@OID = $MethodOID]/odm:Description/odm:TranslatedText/text()"/>
        </xsl:element>
        <xsl:element name="algorithmtype"><xsl:value-of select="$MethodDefs[@OID = $MethodOID]/@Type"/></xsl:element>
        <xsl:element name="formalexpression">
          <xsl:value-of select="$MethodDefs[@OID = $MethodOID]/odm:FormalExpression/text()"/>
        </xsl:element>
        <xsl:element name="formalexpressioncontext">
          <xsl:value-of select="$MethodDefs[@OID = $MethodOID]/odm:FormalExpression/@Context"/>
        </xsl:element>
        <xsl:element name="comment">
          <xsl:value-of select="$CommentDefs[@OID = $CommentOID]/odm:Description/odm:TranslatedText/text()"/>
        </xsl:element>
        <xsl:element name="studyversion"><xsl:value-of select="$MetaDataVersion/@OID"/></xsl:element>
        <xsl:element name="standard"><xsl:value-of select="$MetaDataVersion/@def:StandardName"/></xsl:element>
        <xsl:element name="standardversion"><xsl:value-of select="$MetaDataVersion/@def:StandardVersion"/></xsl:element>
      </xsl:element>
      
    </xsl:for-each>
  </xsl:template>
  
</xsl:stylesheet>