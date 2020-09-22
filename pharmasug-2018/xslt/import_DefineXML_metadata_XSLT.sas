%let Root=C:/_Data/Presentations/PharmaSUG_2018/Accessing_DefineXML;

%include "&Root/xslt/CreateXMLMap.sas";

libname xslt "&Root/xslt/metadata";
libname tmplts "&Root/templates";
libname metadata "&Root/xslt/metadata";
options ls=140;

* filename xml "&Root/xml/define-sdtm-3.1.2.xml";
* filename xml "&Root/xml/define2-0-0-example-adam-results.xml";
filename xml "&Root/xml/define2-0-0-example-sdtm.xml";

filename xsl "&Root/xslt/stylesheets/DefineXML.xsl";
filename flatxml "&Root/xslt/out/DefineXML_flat.xml";

proc xsl in=xml xsl=xsl out=flatxml; 
run;


***************************************************************************;
*** Table metadata                                                      ***;
***************************************************************************;
filename tabmap "&Root/xslt/out/definexml_tables.map";

%CreateXMLMap(
  library=tmplts, 
  metadatadataset=studytablemetadata,
  tablepath=LIBRARY/ItemGroupDef, 
  tablename=table_metadata,   
  mapfileref=tabmap
);

libname define xmlv2 xmlfileref=flatxml xmlmap=tabmap;

data work.table_metadata;
  set define.table_metadata;
  sasref = "SRCDATA";
  state = "Final";
run;

proc sort data=work.table_metadata out=metadata.table_metadata;
  by table;
run;  

***************************************************************************;
*** Column metadata                                                     ***;
***************************************************************************;
filename colmap "&Root/xslt/out/definexml_columns.map";

%CreateXMLMap(
  library=tmplts, 
  metadatadataset=studycolumnmetadata,
  tablepath=LIBRARY/ItemRefItemDef, 
  tablename=column_metadata,   
  mapfileref=colmap 
);

libname define xmlv2 xmlfileref=flatxml xmlmap=colmap;

data work.column_metadata;
  set define.column_metadata;
  sasref = "SRCDATA";
  type = ifc(xmldatatype in ('integer' 'float'), 'N', 'C');
  if missing(length) and xmldatatype in 
     ('datetime' 'date' 'time' 'partialDate' 'partialTime' 
      'partialDatetime' 'incompleteDatetime' 'durationDatetime') 
     then length=64;
run;

proc sort data=work.column_metadata out=metadata.column_metadata;
  by table order;
run;  
