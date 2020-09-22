%let Root=C:/_Data/Presentations/PharmaSUG_2018/Accessing_DefineXML;

libname groovy "&Root/groovy/metadata";
libname tmplts "&Root/templates";
libname metadata "&Root/Groovy/metadata";
options ls=140;

proc format;
  value $typ 'char'='$' num=' ';
run;  

/*
filename opencsv "%sysfunc(pathname(work,l))/opencsv-4.1.jar";
proc http
   method = "get"
   url    = "https://sourceforge.net/projects/opencsv/files/latest/download?source=files"
   out    = opencsv;
run;
*/

filename opencsv "&Root/groovy/opencsv-4.1.jar";
filename groovy "&Root/groovy/groovy-all-2.4.14.jar";
proc groovy; 
  add classpath=groovy;
  add classpath=opencsv;
  execute parseonly "&Root/groovy/import_DefineXML_metadata.groovy";
run;

%let xmlFile=&Root/xml/define2-0-0-example-sdtm.xml;
%let xsdFile=&Root/schema-repository/cdisc-definexml-2.0.0/define2-0-0.xsd;
%let csvOutputFolder=&Root/groovy/metadata;
%*let csvOutputFolder=%sysfunc(pathname(work));
%let tableMetadataCSV=&csvOutputFolder/tablemetadata.csv;
%let columnMetadataCSV=&csvOutputFolder/columnmetadata.csv;

data _null_;
   declare javaobj validatexml("ValidateXML");
   validatexml.exceptiondescribe(1);
   validatexml.callVoidMethod("validateXML", "&xmlFile", "&xsdFile");
   validatexml.delete();
   
   declare javaobj tables("TableMetadataSlurper");
   tables.exceptiondescribe(1);
   tables.callVoidMethod("setXmlFilename", "&xmlFile");
   tables.callVoidMethod("setCsvFilename", "&tableMetadataCSV");
   tables.callVoidMethod("createTableMetadata");
   tables.delete();

   declare javaobj columns("ColumnMetadataSlurper");
   columns.exceptiondescribe(1);
   columns.setStringField("xmlFilename", "&xmlFile");
   columns.setStringField("csvFilename", "&columnMetadataCSV");
   columns.callVoidMethod("createColumnMetadata");
   columns.delete();
run;

***************************************************************************;
*** Table  metadata                                                     ***;
***************************************************************************;
proc sql noprint;
  select catx(' ', name, cats(put(type, $typ.))) into: tableinput separated by ' '
  from dictionary.columns
  where (upcase(libname)='TMPLTS' and upcase(memname)='STUDYTABLEMETADATA')
  order by varnum
  ;
  select catx(' ', name, cats(put(type, $typ.)), length) into: tablelength separated by ' '
  from dictionary.columns
  where (upcase(libname)='TMPLTS' and upcase(memname)='STUDYTABLEMETADATA')
  order by varnum
  ;
quit;
%put &=tableinput;
%put &=tablelength;

data work.table_metadata;
  infile "&csvOutputFolder/tablemetadata.csv" delimiter='09'x missover dsd lrecl=32767 firstobs=2 ;
  length &tablelength;
  input &tableinput;
run;

data work.table_metadata;
  set tmplts.studytablemetadata work.table_metadata;
  comment=tranwrd(comment, "\n", '0A'x);
run;

proc sort data=work.table_metadata out=metadata.table_metadata;
  by table;
run;  

***************************************************************************;
*** Column metadata                                                     ***;
***************************************************************************;
proc sql noprint;
  select catx(' ', name, cats(put(type, $typ.))) into: columninput separated by ' '
  from dictionary.columns
  where (upcase(libname)='TMPLTS' and upcase(memname)='STUDYCOLUMNMETADATA')
  order by varnum
  ;
  select catx(' ', name, cats(put(type, $typ.), length)) into: columnlength separated by ' '
  from dictionary.columns
  where (upcase(libname)='TMPLTS' and upcase(memname)='STUDYCOLUMNMETADATA')
  order by varnum
  ;
quit;
%put &=columninput;
%put &=columnlength;

data work.column_metadata;
  infile "&csvOutputFolder/columnmetadata.csv" delimiter='09'x missover dsd lrecl=32767 firstobs=2 ;
  length &columnlength;
  input &columninput;
run;
data work.column_metadata;
  set tmplts.studycolumnmetadata work.column_metadata;
  comment=tranwrd(comment, "\n", '0A'x);
  algorithm=tranwrd(algorithm, "\n", '0A'x);
  formalexpression=strip(tranwrd(formalexpression, "\n", '0A'x));
  if missing(length) and xmldatatype in 
     ('datetime' 'date' 'time' 'partialDate' 'partialTime' 
      'partialDatetime' 'incompleteDatetime' 'durationDatetime') 
     then length=64;
run;  

proc sort data=work.column_metadata out=metadata.column_metadata;
  by table order;
run;  
