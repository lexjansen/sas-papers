import com.opencsv.CSVWriter
import org.xml.sax.ErrorHandler
import org.xml.sax.SAXParseException
import static javax.xml.XMLConstants.W3C_XML_SCHEMA_NS_URI
import javax.xml.transform.stream.StreamSource
import javax.xml.validation.Schema
import javax.xml.validation.SchemaFactory
import javax.xml.validation.Validator

public class ValidateXML {

  public void validateXML(String xmlFile, String xsdFile) {
    try {
      SchemaFactory factory = SchemaFactory.newInstance( W3C_XML_SCHEMA_NS_URI )
      Schema schema = factory.newSchema( new StreamSource( xsdFile ) )
      Validator validator = schema.newValidator()
    
      List exceptions = []
      Closure<Void> handler = { exception -> exceptions << exception }
      validator.errorHandler = [ warning:    handler,
                               fatalError: handler,
                               error:      handler ] as ErrorHandler
      validator.validate( new StreamSource( xmlFile ) )

      exceptions.each {
        println "ERROR: [validateXML] $xmlFile is not valid."
        println "$it.lineNumber:$it.columnNumber: $it.message"
      }
      
    } catch (FileNotFoundException e) {
      println "ERROR: [validateXML] $xmlFile can not be found."
    } catch (SAXParseException e) {
      println "ERROR: [validateXML] XML schema validation issues with $xmlFile."
      println "ERROR: [validateXML] " + "${e.message}."
    } catch (Exception e) {
      println "ERROR: [validateXML] "+ "${e.message}."
    }    
  }
}

private class DefineXMLParser {
  def parseFile(path) {
      def definexml = new File(path).text
      def define = new XmlSlurper().parseText(definexml)
      def ns = [
        "" : "http://www.cdisc.org/ns/odm/v1.3",
        "def" : "http://www.cdisc.org/ns/def/v2.0",
        "xlink" : "http://www.w3.org/1999/xlink",
        "arm" : "http://www.cdisc.org/ns/arm/v1.0"
        ]
      define.declareNamespace(ns)
      return define
  }
}

private class CSVFile {
  void createCSV(String [] header, List metadata, String path) {
    def csvout = new FileWriter(path)
    try {
      CSVWriter writer = new CSVWriter(csvout, '\t' as char, '\0' as char, '\0' as char);
      writer.writeNext(header)
      writer.writeAll(metadata)
      writer.close()
    } catch (FileNotFoundException e) {
      println "ERROR: [CSVFile] $path could not be found"
    } catch (Exception e) {
      println "ERROR: [CSVFile] " + e.toString()
    }
  }
}

public class TableMetadataSlurper {

  private String xmlFilename = null
  private String csvFilename = null

  public void setXmlFilename(String xmlFilename) {
      this.xmlFilename = xmlFilename
  }

  public void setCsvFilename(String csvFilename) {
      this.csvFilename = csvFilename
  }

  public void createTableMetadata() {

    DefineXMLParser myParser = new DefineXMLParser()
    try {
      def define = myParser.parseFile(xmlFilename)     

      String [] header = ["sasref", "table", "label", "order", "repeating", "isreferencedata", "domain", 
                          "domaindescription", "class", "xmlpath", "xmltitle", 
                          "structure", "purpose", "keys", "state", "date", "comment", "studyversion", "standard", "standardversion"
                         ]
      String creationDateTime = define.@CreationDateTime.toString().substring(0,10)
      String studyVersion = define.Study.MetaDataVersion.@OID.toString()
      String standard = define.Study.MetaDataVersion.@'def:StandardName'.toString()
      String standardVersion = define.Study.MetaDataVersion.@'def:StandardVersion'.toString()
      Integer order=0
      
      def itemGroups=[]
      def itemGroupDefs = define.Study.MetaDataVersion.ItemGroupDef

      itemGroupDefs.each {  
        
        def itemRefs = it.ItemRef
        Map keyMap = [:]
        itemRefs.each {
            if (it.@KeySequence.toString() != "") {
                def itemOID = it.@ItemOID
                def itemDef = define.Study.MetaDataVersion.ItemDef.find {it.@OID == itemOID}
                keyMap[(it.@KeySequence).toInteger()]= itemDef.@Name
            }
        }
        String keys = keyMap.sort { a, b -> a.key <=> b.key }.values().toArray().join(' ')


        order+=1
        String commentOID = it.'@def:CommentOID'.toString()
        def commentDef = define.Study.MetaDataVersion.'def:CommentDef'.find {it.@OID == commentOID}
        String archiveLocationID = it.'@def:ArchiveLocationID'.toString()
        def leaf = it.'def:leaf'.find {it.@ID == archiveLocationID}
        def domainDescription = it.Alias.find {it.@Context == 'DomainDescription'}

        String[] itemGroup = new String[header.size()]
        itemGroup = [
          'SRCDATA',
          it.@Name.toString(),
          it.Description.TranslatedText.text(),
          order.toString(),
          it.@Repeating.toString(),
          it.@IsReferenceData.toString(),
          it.@Domain.toString(),
          domainDescription.@Name.toString(),
          it.'@def:Class'.toString(),
          leaf.'@xlink:href'.toString(),
          leaf.'def:title'.toString(),
          it.'@def:Structure'.toString(),
          it.@Purpose.toString(),
          keys,
          'Final',
          creationDateTime,
          commentDef.Description.TranslatedText.text().trim().replace("\n", "\\n"),
          studyVersion,
          standard,
          standardVersion
        ]
        itemGroups << itemGroup
        
      }

      CSVFile csvFile = new CSVFile()
      try {
        csvFile.createCSV(header, itemGroups, csvFilename)
      } catch (FileNotFoundException e) {
        println "ERROR: [createTableMetadata] $csvFilename can not be created."
      }

    } catch (FileNotFoundException e) {
      println "ERROR: [createTableMetadata] $xmlFilename can not be found."
    } catch (Exception e) {
      println "ERROR: [createTableMetadata] " + e.toString()
    }
  }
}

public class ColumnMetadataSlurper {

  private String xmlFilename = null
  private String csvFilename = null

  public void setXmlFilename(String xmlFilename) {
      this.xmlFilename = xmlFilename
  }

  public void setCsvFilename(String csvFilename) {
      this.csvFilename = csvFilename
  }

  public void createColumnMetadata() {

    DefineXMLParser myParser = new DefineXMLParser()
    try {
      def define = myParser.parseFile(xmlFilename)     

      String [] header = ["sasref", "table", "column", "label", "order", "type", "length", "displayformat", 
                          "significantdigits", "xmldatatype", "xmlcodelist", "core", "origin", "origindescription", 
                          "Role", "algorithm", "algorithmtype", "formalexpression", "formalexpressioncontext", 
                          "comment", "studyversion", "standard", "standardversion"
                         ]
      String studyVersion = define.Study.MetaDataVersion.@OID.toString()
      String standard = define.Study.MetaDataVersion.@'def:StandardName'.toString()
      String standardVersion = define.Study.MetaDataVersion.@'def:StandardVersion'.toString()
      
      def items = []
      def itemGroupDefs = define.Study.MetaDataVersion.ItemGroupDef
      
      itemGroupDefs.each {
        
        def itemRefs = it.ItemRef
        itemRefs.each {  
          
          String itemOID = it.@ItemOID.toString()
          def itemDef = define.Study.MetaDataVersion.ItemDef.find {it.@OID == itemOID}
          String commentOID = itemDef.'@def:CommentOID'.toString()
          def commentDef = define.Study.MetaDataVersion.'def:CommentDef'.find {it.@OID == commentOID}
          String methodOID = it.@MethodOID.toString()
          def methodDef = define.Study.MetaDataVersion.MethodDef.find{it.@OID == methodOID}
          
          String dataType = itemDef.@DataType.toString()
          String type = null
          if (dataType == 'float' | dataType == 'integer') {
              type = 'N'
            } else {
              type = 'C'
          }
          
          String[] item = new String[header.size()]
          item = [
            'SRCDATA',
            it.parent().@Name.toString(),
            itemDef.@Name.toString(),
            itemDef.Description.TranslatedText.text(),
            it.@OrderNumber.toString(),
            type,
            itemDef.@Length.toString(),
            itemDef.@'def:DisplayFormat'.toString(),
            itemDef.@SignificantDigits.toString(),
            itemDef.@DataType.toString(),
            itemDef.CodeListRef.@CodeListOID.toString(),
            '',
            itemDef.'def:Origin'.@Type.toString(),
            itemDef.'def:Origin'.Description.TranslatedText.toString(),
            it.@Role.toString(),
            methodDef.Description.TranslatedText.text().trim().replace("\n", "\\n"),
            methodDef.@Type.toString(),
            methodDef.FormalExpression.text().trim().replace("\n", "\\n"),
            methodDef.FormalExpression.@Context.toString(),
            commentDef.Description.TranslatedText.text().trim().replace("\n", "\\n"),
            studyVersion,
            standard,
            standardVersion
          ]
          items << item
          
        }
      }
      CSVFile csvFile = new CSVFile()
      try {
        csvFile.createCSV(header, items, csvFilename)
      } catch (FileNotFoundException e) {
        println "ERROR: [createColumnMetadata] $csvFilename can not be created."
      }
    
    } catch (FileNotFoundException e) {
      println "ERROR: [createColumnMetadata] $xmlFilename can not be found."
    } catch (Exception e) {
      println "ERROR: [createTableMetadata] " + e.toString()
    }
  }
}
