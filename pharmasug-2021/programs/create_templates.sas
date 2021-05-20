%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;




%* Generic configuration;
%include "&project_folder/programs/config.sas";

proc sql;
    create table tmplts.tabulation_table
    (
      NAME char(32),
      DESCRIPTION char(256),
      STRUCTURE char(1024),
      ORDER num,
      REQUIREDFORSTANDARD char(4),
      COMMENT char(2000),
      DOMAIN char(255),
      DOMAINDESCRIPTION char(256),
      CLASS char(64),
      PURPOSE char(16),
      CUSTOMTABLE char(4),
      TABLEREFERENCENOTE char(2500),
      REPEATING char(4),
      ISREFERENCEDATA char(4),
      ARCHIVEPATH char(944),
      ARCHIVETITLE char(255)
    );
    create table tmplts.tabulation_column
    (
      TABLENAME char(32),
      NAME char(32),
      DESCRIPTION char(256),
      ORDER num,
      CORE char(4),
      MANDATORY char(3),
      ORIGINTYPE char(128),
      CODELISTREFERENCE	char(64),
      COMPUTATIONALMETHOD char(2000),
      SUBMISSIONDATATYPE char(32),
      CLASSCOLUMN char(32),
      SUBMISSIONDATATYPE char(32),
      SASLENGTH	num,
      ORIGINDESCRIPTION	 char(128),
      ROLE char(64),
      KEYSEQUENCE	num,
      DISPLAYFORMAT char(64),
      SIGNIFICANTDIGITS num,
      XMLDATATYPE char(32),
      COMMENT char(2000),
      COMPUTATIONALMETHODTYPE char(32),
      FORMALEXPRESSION char(2000),
      FORMALEXPRESSIONCONTEXT char(1024),
      COLUMNISNONSTANDARD char(4),
      COLUMNREFERENCEFORMAT char(64),
      COLUMNREFERENCENOTE char(2500)      
    );  
    create table tmplts.tabulation_columnclassgroup
    (
      NAME char(255),
      DESCRIPTION char(1024),
      TABLEREFERENCENOTE char(2500)
    );  
    create table tmplts.tabulation_columnclass
    (
      COLUMNGROUPNAME char(255),
      NAME char(32),
      DESCRIPTION char(256),
      ORDER num,
      CORE char(4),
      MANDATORY char(3),
      ORIGINTYPE char(128),
      CODELISTREFERENCE	char(64),
      COMPUTATIONALMETHOD char(2000),
      SUBMISSIONDATATYPE char(32),
      SASLENGTH	num,
      ROLE char(64),
      ORIGINDESCRIPTION	 char(128),
      KEYSEQUENCE	num,
      DISPLAYFORMAT char(64),
      SIGNIFICANTDIGITS num,
      XMLDATATYPE char(32),
      COMMENT char(2000),
      COMPUTATIONALMETHODTYPE char(32),
      FORMALEXPRESSION char(2000),
      FORMALEXPRESSIONCONTEXT char(1024),
      COLUMNISNONSTANDARD char(4),
      COLUMNREFERENCEFORMAT char(64),
      COLUMNREFERENCENOTE char(2500)      
    );  
    create table tmplts.analysis_table
    (
      NAME char(32),
      DESCRIPTION char(256),
      STRUCTURE char(1024),
      ORDER num,
      REQUIREDFORSTANDARD char(4),
      COMMENT char(2000),
      CLASS char(64),
      PURPOSE char(16),
      NONADAMANALYSISTABLE char(4),
      TABELREFERENCENOTE char(2500),
      REPEATING char(4),
      ISREFERENCEDATA char(4),
      ARCHIVEPATH char(944),
      ARCHIVETITLE char(255)
    );
    create table tmplts.analysis_column
    (
      TABLENAME char(32),
      NAME char(32),
      DESCRIPTION char(256),
      ORDER num,
      CORE char(4),
      MANDATORY char(3),
      ORIGINTYPE char(128),
      CODELISTREFERENCE	char(64),
      COMPUTATIONALMETHOD char(2000),
      SUBMISSIONDATATYPE char(32),
      CLASSCOLUMN char(32),
      SUBMISSIONDATATYPE char(32),
      SASLENGTH	num,
      ORIGINDESCRIPTION	 char(128),
      KEYSEQUENCE	num,
      DISPLAYFORMAT char(64),
      SIGNIFICANTDIGITS num,
      XMLDATATYPE char(32),
      COMMENT char(2000),
      COMPUTATIONALMETHODTYPE char(32),
      FORMALEXPRESSION char(2000),
      FORMALEXPRESSIONCONTEXT char(1024),
      COLUMNREFERENCEFORMAT char(64),
      COLUMNREFERENCENOTE char(2500)      
    );  
    create table tmplts.analysis_columnclassgroup
    (
      NAME char(255),
      DESCRIPTION char(1024),
      CLASS char(64),
      TABLEREFERENCENOTE char(2500)
    );
    create table tmplts.analysis_columnclass
    (
      COLUMNGROUPNAME char(255),
      NAME char(32),
      DESCRIPTION char(256),
      ORDER num,
      CORE char(4),
      MANDATORY char(3),
      ORIGINTYPE char(128),
      CODELISTREFERENCE	char(64),
      COMPUTATIONALMETHOD char(2000),
      SUBMISSIONDATATYPE char(32),
      SASLENGTH	num,
      ORIGINDESCRIPTION	 char(128),
      KEYSEQUENCE	num,
      DISPLAYFORMAT char(64),
      SIGNIFICANTDIGITS num,
      XMLDATATYPE char(32),
      COMMENT char(2000),
      COMPUTATIONALMETHODTYPE char(32),
      FORMALEXPRESSION char(2000),
      FORMALEXPRESSIONCONTEXT char(1024),
      COLUMNREFERENCEFORMAT char(64),
      COLUMNREFERENCENOTE char(2500)      
    );  
  create table tmplts.terminology
    (
      NAME char(255),
      DESCRIPTION char(1024),
      STANDARD char(32),
      RELEASEDATE char(32),
      SOURCE char(100),
      SOURCEVERSION char(20),
      CODELIST_SHORTNAME char(70),
      CODELIST_NAME char(255),
      CODELIST_DESCRIPTION char(1024),
      CODELIST_CODE char(8),
      CODELIST_DATATYPE char(8),
      CODELIST_SASFORMATNAME char(8),
      CODELIST_PREFERRED_TERM char(200),
      CODELIST_EXTENSIBLE char(3),
      CODELIST_EXTENSIBLE_STUDY char(3),
      CODELIST_SUBSETTABLE char(3),
      CODED_VALUE char(160),
      DECODED_VALUE char(160),
      CODE char(8),
      SYNONYMS char(800),
      DEFINITION char(2000),
      PREFERRED_TERM char(200),
      ORDER_NUMBER num,
      RANK num,
      EXTENDED char(3)
    );
  ;
quit;