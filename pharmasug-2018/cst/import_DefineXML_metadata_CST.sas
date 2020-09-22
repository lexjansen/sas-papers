**********************************************************************************;
*                                                                                *;
* Sample program to import metadata from a CDISC-DEFINE-XML V2.0.0 file          *;
*                                                                                *;
**********************************************************************************;

%let Root=C:/_Data/Presentations/PharmaSUG_2018/Accessing_DefineXML;

%let _cstStandard=CDISC-DEFINE-XML;
%let _cstStandardVersion=2.0.0;

%let _cstTrgStandard=CDISC-SDTM;
%let _cstTrgStandardVersion=3.1.2;
%let _cstDefineFile=define2-0-0-example-sdtm.xml;
%let workPath=%sysfunc(pathname(work));

*****************************************************************************************;
* One strategy to defining the required library and file metadata for a CST process     *;
*  is to optionally build SASReferences in the WORK library.  An example of how to do   *;
*  this follows.                                                                        *;
*                                                                                       *;
* The call to cstutil_processsetup below tells CST how SASReferences will be provided   *;
*  and referenced.  If SASReferences is built in work, the call to cstutil_processsetup *;
*  may, assuming all defaults, be as simple as:                                         *;
*        %cstutil_processsetup()                                                        *;
*****************************************************************************************;

%let _cstSetupSrc=SASREFERENCES;

%cst_createdsfromtemplate(_cstStandard=CST-FRAMEWORK, _cstType=control,_cstSubType=reference, _cstOutputDS=work.sasreferences);

proc sql;
  insert into work.sasreferences
  values("CST-FRAMEWORK"    "1.2"                   "messages"          ""           "messages" "libref"  "input"  "dataset"  "N"  "" ""          1  ""                        "")
  values("&_cstStandard"    "&_cstStandardVersion"  "messages"          ""           "crtmsg"   "libref"  "input"  "dataset"  "N"  "" ""          2  ""                        "")
  values("&_cstStandard"    "&_cstStandardVersion"  "autocall"          ""           "crtcode"  "fileref" "input"  "folder"   "N"  "" ""          1  ""                        "")
  values("&_cstStandard"    "&_cstStandardVersion"  "properties"        "initialize" "inprop"   "fileref" "input"  "file"     "N"  "" ""          1  ""                         "")

  values("&_cstStandard"    "&_cstStandardVersion"  "results"           "results"    "results"  "libref"  "output" "dataset"  "Y"  "" "&Root/cst/results"      . "xml2source_results_sdtm"  "")
  values("&_cstStandard"    "&_cstStandardVersion"  "externalxml"       "xml"        "crtxml"   "fileref" "input"  "file"     "N"  "" "&Root/xml"              . "&_cstDefineFile"          "")
  values("&_cstStandard"    "&_cstStandardVersion"  "referencexml"      "map"        "crtmap"   "fileref" "input"  "file"     "N"  "" "&Root/cst/referencexml" . "define.map"               "")
  values("&_cstStandard"    "&_cstStandardVersion"  "sourcedata"        ""           "srcdata"  "libref"  "output" "folder"   "Y"  "" "&workPath"              . ""                         "")
  values("&_cstStandard"    "&_cstStandardVersion"  "studymetadata"     "study"      "trgmeta"  "libref"  "output" "folder"   "Y"  "" "&Root/cst/metadata"     . ""                         "")

  values("&_cstTrgStandard" "&_cstTrgStandardVersion"  "referencemetadata" "table"      "refmeta"  "libref"  "input"  "dataset"  "N"  "" ""          . ""                         "")
  values("&_cstTrgStandard" "&_cstTrgStandardVersion"  "referencemetadata" "column"     "refmeta"  "libref"  "input"  "dataset"  "N"  "" ""          . ""                         "")
  values("&_cstTrgStandard" "&_cstTrgStandardVersion"  "classmetadata"     "column"     "refmeta"  "libref"  "input"  "dataset"  "N"  "" ""          . ""                         "")
  values("&_cstTrgStandard" "&_cstTrgStandardVersion"  "classmetadata"     "table"      "refmeta"  "libref"  "input"  "dataset"  "N"  "" ""          . ""                         "")
  ;
quit;

****************************************************;
* Process SASReferences file.                      *;
****************************************************;
%cstutil_processsetup();


***************************************************************************;
* Run the schema validation macro.                                        *;
***************************************************************************;
%cstutilxmlvalidate();

*******************************************************************************;
* Run the standard-specific Define-XML macros.                                *;
*******************************************************************************;
%define_read();

*******************************************************************************;
* Run the standard-specific Define-XML macros.                                *;
*******************************************************************************;

%define_createsrcmetafromdefine(
  _cstDefineDataLib=srcdata,
  _cstTrgStandard=&_cstTrgStandard,
  _cstTrgStandardVersion=&_cstTrgStandardVersion,
  _cstTrgStudyDS=trgmeta.source_study,
  _cstTrgTableDS=trgmeta.source_tables,
  _cstTrgColumnDS=trgmeta.source_columns,
  _cstTrgCodeListDS=trgmeta.source_codelists,
  _cstTrgValueDS=trgmeta.source_values,
  _cstTrgDocumentDS=trgmeta.source_documents,
  _cstTrgAnalysisResultDS=trgmeta.source_analysisresults,
  _cstLang=en,
  _cstUseRefLib=Y,
  _cstRefTableDS=refmeta.reference_tables,
  _cstRefColumnDS=refmeta.reference_columns,
  _cstClassTableDS=refmeta.class_tables,
  _cstClassColumnDS=refmeta.class_columns
  );

