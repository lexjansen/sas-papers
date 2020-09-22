libname csttmp ".";

***********************************************;
*  Build templates as 0-obs data sets         *;
***********************************************;

%************************************************************************************;

proc sql;
  * Build source study metadata data set template. *;
  create table csttmp.studystudymetadata( label='Source Study Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     fileoid char(128) label='Unique identifier for the file',
     studyoid char(128) label='Unique identifier for the study',
     studyname char(128) label='Short external name for the study',
     studydescription char(2000) label='Description of the study',
     protocolname char(128) label='Sponsors internal name for the protocol',
     formalstandardname char(2000) label='Formal Name of Standard',
     formalstandardversion char(2000) label='Formal Version of Standard',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );

  * Build source table metadata data set template. *;
  create table csttmp.studytablemetadata( label='Source Table Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     table char(32) label='Table Name',
     label char(200) label='Table Label',
     order num label='Table order',
     repeating char(3) label="Can itemgroup occur repeatedly within the containing form?",
     isreferencedata char(3) LABEL="Can itemgroup occur only within a ReferenceData element?",
     domain char(32) label='Domain',
     domaindescription char(256) label='Domain description',
     class char(40) label='Observation Class within Standard',
     xmlpath char(200) label='(Relative) path to xpt file',
     xmltitle char(200) label='Title for xpt file',
     structure char(200) label='Table Structure',
     purpose char(10) label='Purpose',
     keys char(200) label='Table Keys',
     state char(20) label='Data Set State (Final, Draft)',
     date char(20) label='Release Date',
     comment char(1000) label='Comment',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );

  * Build source column metadata data set template. *;
  create table csttmp.studycolumnmetadata( label='Source Column Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     table char(32) label='Table Name',
     column char(32) label='Column Name',
     label char(200) label='Column Description',
     order num label='Column Order',
     type char(1) label='Column Type',
     length num label='Column Length',
     displayformat char(200) label='Display Format',
     significantdigits num label='Significant Digits',
     xmldatatype char(18) label='XML Data Type',
     xmlcodelist char(128) label='SAS Format/XML Codelist',
     core char(10) label='Column Required or Optional',
     origin char(40) label='Column Origin',
     origindescription char(1000) label='Column Origin Description',
     role char(200) label='Column Role',
     algorithm char(1000) label='Computational Algorithm or Method',
     algorithmtype char(11) label='Type of Algorithm',
     formalexpression char(1000) label='Formal Expression for Algorithm',
     formalexpressioncontext char(1000) label='Context to be used when evaluating the FormalExpression content',
     comment char(1000) label='Comment',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );

  * Build source value metadata data set template. *;
  create table csttmp.studyvaluemetadata( label='Source Value Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     table char(32) label='Table Name',
     column char(32) label='Column Name',
     whereclause char(1000) label='Where Clause',
     whereclausecomment char(1000) label='Where Clause comment',
     label char(200) label='Column Description',
     order num label='Column Order',
     type char(1) label='Column Type',
     length num label='Column Length',
     displayformat char(200) label='Display Format',
     significantdigits num label='Significant Digits',
     xmldatatype char(18) label='XML Data Type',
     xmlcodelist char(128) label='SAS Format/XML Codelist',
     core char(10) label='Column Required or Optional',
     origin char(40) label='Column Origin',
     origindescription char(1000) label='Column Origin Description',
     role char(200) label='Column Role',
     algorithm char(1000) label='Computational Algorithm or Method',
     algorithmtype char(11) label='Type of Algorithm',
     formalexpression char(1000) label='Formal Expression for Algorithm',
     formalexpressioncontext char(1000) label='Context to be used when evaluating the FormalExpression content',
     comment char(1000) label='Comment',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );

  * Build source codelist metadata data set template. *;
  create table csttmp.studycodelistmetadata( label='Source Codelist Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     codelist char(128) label='Unique identifier for this CodeList',
     codelistname char(128) label='CodeList Name',
     codelistdescription char(2000) label='CodeList Description',
     codelistncicode char(10) label='Codelist NCI Code',
     codelistdatatype char(7) label='CodeList item value data type (integer | float | text | string)',
     sasformatname char(32) label='SAS format name',
     codedvaluechar char(512) label='Value of the codelist item (character)',
     codedvaluenum num label='Value of the codelist item (numeric)',
     decodetext char(2000) label='Decode value of the codelist item',
     decodelanguage char(17) label='Language',
     codedvaluencicode char(10) label='Codelist Item NCI Code',
     rank num label='CodedValue order relative to other item values',
     ordernumber num label='Display order of the item within the CodeList.',
     extendedvalue char(3) label='Coded value that has been used to extend external controlled terminology',
     dictionary char(200) label='Name of the external codelist',
     version char(200) label='Version designator of the external codelist',
     ref char(512) label='Reference to a local instance of the dictionary',
     href char(512) label='URL of an external instance of the dictionary',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );


  * Build source document metadata data set template. *;
  create table csttmp.studydocumentmetadata( label='Source Document Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     doctype char(10) label='Document Type',
     href char(512) label='The pathname and filename of the target dataset relative to the define.xml',
     title char(2000) label='Meaningful description, label, or location of the document leaf',
     pdfpagereftype char(16) label='Type of Page Reference (PhysicalRef/NamedDestination)',
     pdfpagerefs char(200) label='Page Reference',
     table char(32) label='Table Name',
     column char(32) label='Column Name',
     whereclause char(1000) label='Where Clause',
     displayidentifier char(128) label='Analysis Display Identifier',
     resultidentifier char(128) label='Analysis Display Result Identifier',
     studyversion char(128) label='Unique study version identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
    );

  * Build source results metadata data set template. *;
  create table csttmp.studyanalysisresultmetadata( label='Source Analysis Results Metadata')
    (
     sasref char(8) label='SASreferences sourcedata libref',
     displayidentifier char(128) label='Unique identifier for analysis display',
     displayname char(2000) label='Title of display',
     displaydescription char(2000) label='Description of display',
     resultidentifier char(128) label='Specific analysis result within display',
     resultdescription char(2000) label='Description of analysis result within display',
     parametercolumn char(8) label='Name of the column that holds the parameter',
     analysisreason char(2000) label='Reason for analysis',
     analysispurpose char(2000) label='Purpose of analysis',
     tablejoincomment char(2000) label='Comment describing how to join tables',
     resultdocumentation char(2000) label='Documentation of analysis result within display',
     codecontext char(128) label='Name and version of computer language',
     code char(2000) label='Programming statements',
     table char(32) label='Table Name',
     analysisvariables char(1024) label='Analysis Variable List',
     whereclause char(1000) label='Where Clause',
     studyversion char(128) label='Unique Study Version Identifier',
     standard char(20) label='Name of Standard',
     standardversion char(20) label='Version of Standard'
  );

quit;
