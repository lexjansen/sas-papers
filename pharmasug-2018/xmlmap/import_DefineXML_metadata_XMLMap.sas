%let Root=C:/_Data/Presentations/PharmaSUG_2018/Accessing_DefineXML;

libname xmlmap "&Root/xmlmap/metadata";
libname tmplts "&Root/templates";
libname metadata "&Root/xmlmap/metadata";
libname out "&Root/xmlmap/out";
options ls=140;

filename define "&Root/xml/define2-0-0-example-sdtm.xml";
filename map "&Root/xmlmap/definexml_auto.map";
libname define xmlv2 automap=reuse xmlmap=map prefixattributes=no;

proc copy in=define out=out;
run;

***************************************************************************;
*** Table metadata                                                      ***;
***************************************************************************;

proc sql;
  create table work.ItemGroupDefKeys
    as select
    igd.OID as ItemGroupDefOID,
    igd.Name as Table,
    ir1.KeySequence,
    id.Name as Column

    from out.Study std
      left join out.MetaDataVersion mdv
    on mdv.Study_ORDINAL = std.Study_ORDINAL      
      left join out.ItemGroupDef igd
    on igd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL
      left join out.ItemRef1 ir1
    on ir1.ItemGroupDef_ORDINAL = igd.ItemGroupDef_ORDINAL
      left join out.ItemDef id
    on (id.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL) and 
       (ir1.ItemOID = id.OID)
    where not missing(keysequence)
    order by table, keysequence 
    ;
quit;   

data work.ItemGroupDefKeys;
  length keys $200;
  retain keys;
  set work.ItemGroupDefKeys;
  by table keysequence;
  if first.table then keys=Column;
                 else keys=catx(' ', keys, Column);
  if last.table;
run;

data work.ItemGroupDef;
 set out.ItemGroupDef;
 order=_n_;
run;

proc sql;
  create table work.table_metadata
    as select
    igd.Name as Table,
    tt.TranslatedText as Label,
    igd.Order,
    igd.Repeating,
    igd.isReferenceData,
    igd.Domain,
    al.Name as DomainDescription,
    igd.Class,
    lf.href as xmlpath,
    lf.title as xmltitle,
    igd.Structure,
    igd.Purpose,
    igdk.Keys,
    put(odm.CreationDateTime, E8601DT.) as Date,
    tt5.TranslatedText5 as Comment,
    mdv.OID as StudyVersion,
    mdv.StandardName as Standard,
    mdv.StandardVersion
    
    from out.ODM odm
      left join out.Study std
    on std.ODM_ORDINAL = odm.ODM_ORDINAL
      left join out.MetaDataVersion mdv
    on mdv.Study_ORDINAL = std.Study_ORDINAL      
      left join work.ItemGroupDef igd
    on igd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL
      left join out.Description des
    on des.ItemGroupDef_ORDINAL = igd.ItemGroupDef_ORDINAL
      left join out.TranslatedText tt
    on tt.Description_ORDINAL = des.Description_ORDINAL
      left join out.Leaf lf
    on lf.ItemGroupDef_ORDINAL = igd.ItemGroupDef_ORDINAL
      left join out.Alias al
    on (al.ItemGroupDef_ORDINAL = igd.ItemGroupDef_ORDINAL) and 
       (al.Context = "DomainDescription")
      left join out.CommentDef comd
    on (comd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL) and 
       (igd.CommentOID = comd.OID)
      left join out.Description4 des4
    on des4.CommentDef_ORDINAL = comd.CommentDef_ORDINAL
      left join out.TranslatedText5 tt5
    on tt5.Description4_ORDINAL = des4.Description4_ORDINAL
      left join work.ItemGroupDefKeys igdk
    on igdk.ItemGroupDefOID = igd.OID
  ; 
quit;

data work.table_metadata;
  set tmplts.studytablemetadata work.table_metadata;
  sasref = "SRCDATA";
  state = "Final";
run;

proc sort data=work.table_metadata out=metadata.table_metadata;
  by table;
run;  

***************************************************************************;
*** Column metadata                                                     ***;
***************************************************************************;
proc sql;
  create table work.column_metadata
    as select
    igd.Name as Table,
    id.Name as Column,
    tt1.TranslatedText1 as Label,
    ir1.OrderNumber as Order,

    case when id.DataType in ("integer","float")
      then 'N'
      else 'C'
    end as type,
    id.Length,
    id.DisplayFormat,
    id.SignificantDigits,
    id.DataType as xmldatatype,
    clr.CodeListOID as xmlcodelist,
    itor.type as origin,
    tt2.TranslatedText2 as origindescription,
    ir1.Role,

    tt4.TranslatedText4 as algorithm,
    metd.Type as algorithmtype,
    formex.Context as formalexpressioncontext,
    formex.FormalExpression as formalexpression,

    tt5.TranslatedText5 as Comment,
    mdv.OID as StudyVersion,
    mdv.StandardName as Standard,
    mdv.StandardVersion
    
    from out.ODM odm
      left join out.Study std
    on std.ODM_ORDINAL = odm.ODM_ORDINAL
      left join out.MetaDataVersion mdv
    on mdv.Study_ORDINAL = std.Study_ORDINAL      
      left join work.ItemGroupDef igd
    on igd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL
      left join out.ItemRef1 ir1
    on ir1.ItemGroupDef_ORDINAL = igd.ItemGroupDef_ORDINAL
      left join out.ItemDef id
    on id.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL and (ir1.ItemOID = id.OID)
      left join out.Description1 des1
    on des1.ItemDef_ORDINAL = id.ItemDef_ORDINAL
      left join out.TranslatedText1 tt1
    on tt1.Description1_ORDINAL = des1.Description1_ORDINAL
    
       left join out.CodeListRef clr
    on clr.ItemDef_ORDINAL = id.ItemDef_ORDINAL
  
       left join out.origin itor
     on itor.ItemDef_ORDINAL = id.ItemDef_ORDINAL
      left join out.Description2 des2
    on des2.Origin_ORDINAL = itor.Origin_ORDINAL
      left join out.TranslatedText2 tt2
    on tt2.Description2_ORDINAL = des2.Description2_ORDINAL
  
       left join out.methoddef metd
     on (metd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL) and (ir1.MethodOID = metd.OID)
      left join out.Description3 des3
    on des3.MethodDef_ORDINAL = metd.MethodDef_ORDINAL
      left join out.TranslatedText4 tt4
    on tt4.Description3_ORDINAL = des3.Description3_ORDINAL
      left join out.FormalExpression formex
    on formex.MethodDef_ORDINAL = metd.MethodDef_ORDINAL
    
      left join out.CommentDef comd
    on (comd.MetaDataVersion_ORDINAL = mdv.MetaDataVersion_ORDINAL) and (id.CommentOID = comd.OID)
      left join out.Description4 des4
    on des4.CommentDef_ORDINAL = comd.CommentDef_ORDINAL
      left join out.TranslatedText5 tt5
    on tt5.Description4_ORDINAL = des4.Description4_ORDINAL
  ; 
quit;

data work.column_metadata;
  set tmplts.studycolumnmetadata work.column_metadata;
  sasref = "SRCDATA";
  /* Date/Time related items do not have a length in Define-XML */
  if missing(length) and xmldatatype in 
     ('datetime' 'date' 'time' 'partialDate' 'partialTime' 
      'partialDatetime' 'incompleteDatetime' 'durationDatetime') 
     then length=64;
run;

proc sort data=work.column_metadata out=metadata.column_metadata;
  by table order;
run;  
