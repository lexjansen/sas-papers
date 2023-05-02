%global project_folder;
%let project_folder=c:/_github/lexjansen/sas-papers/pharmasug-2023;
%* Generic configuration;
%include "&project_folder/programs/config.sas";

*******************************************************************************;
* Create CT metadata                                                          *;
*******************************************************************************;

data sdtm_specializations_ct(drop=i countwords);
  length term $100;
  set data.sdtm_specializations(
    keep=datasetSpecializationId shortname vlmTarget domain name codelist codelist_submission_value subsetcodelist value_list assigned_term assigned_value
    where=(not missing(codelist))
    );
  if not missing(value_list) then do;
    countwords=countw(value_list, ";");
    do i=1 to countwords;
      term=strip(scan(value_list, i, ";"));
      if not missing(term) then output;
    end;
  end;
  else do;
    term  = assigned_value;
    output;
  end;  
run;  

proc sort data=sdtm_specializations_ct;
  by codelist;
run;
  
data sdtm_specializations_ct;
  set sdtm_specializations_ct;
  length xmlcodelist $128;
  /* Assign codelists */

  xmlcodelist = codelist_submission_value;
  if (not missing(codelist_submission_value)) and (not missing(assigned_value)) and name in ("VSORRESU" "LBORRESU")
    then xmlcodelist = cats(codelist_submission_value, "_ORU_", datasetSpecializationId);
  if (not missing(codelist_submission_value)) and (not missing(assigned_value)) and name in ("VSSTRESU" "LBSTRESU")
    then xmlcodelist = cats(codelist_submission_value, "_STU_", datasetSpecializationId);

  if (not missing(codelist_submission_value)) and (not missing(value_list)) and name in ("VSORRESU" "LBORRESU")
    then xmlcodelist = cats(codelist_submission_value, "_ORU_", datasetSpecializationId);
  if (not missing(codelist_submission_value)) and (not missing(value_list)) and name in ("VSSTRESU" "LBSTRESU")
    then xmlcodelist = cats(codelist_submission_value, "_STU_", datasetSpecializationId);

  if (not missing(value_list)) and (not missing(subsetcodelist)) then do;
    output;
    xmlcodelist = subsetcodelist;
  end;  

  output;  
/*
  if (not missing(codelist_submission_value)) and (not missing(value_list)) and name in ("VSORRES" "LBORRES")
    then xmlcodelist = cats(codelist_submission_value, "_OR_", datasetSpecializationId);
  if (not missing(codelist_submission_value)) and (not missing(value_list)) and name in ("VSSTRESC" "LBSTRESC")
    then xmlcodelist = cats(codelist_submission_value, "_ST_", datasetSpecializationId);
*/
run;

options ls=200;  

ods listing close;
ods html5 file="&project_folder/programs/05_create_ct_metadata.html";
ods excel file="&project_folder/programs/05_create_ct_metadata.xlsx" options(sheet_name="CT" flow="tables" autofilter = 'all');

  proc print data=sdtm_specializations_ct;
  var domain datasetSpecializationId name codelist codelist_submission_value xmlcodelist subsetcodelist term assigned_term assigned_value value_list;
  run;

ods excel close;
ods html5 close;
ods listing;

proc sort data=sdtm_specializations_ct;
  by codelist xmlcodelist term;
run;  
  

proc sql;
  create table work.source_codelists_sdtm as
  select 
      sdtm_ct.*,
      ct_vlm.xmlcodelist as xmlcodelist__,
      ct_vlm.term as term__,
      ct_vlm.shortname,
      ct_vlm.subsetcodelist,
      ct_vlm.name as column,
      ct_vlm.datasetSpecializationId      
  from data.sdtm_ct sdtm_ct, sdtm_specializations_ct ct_vlm
  where (sdtm_ct.codelistncicode = ct_vlm.codelist) and 
        ((sdtm_ct.codedvaluechar = ct_vlm.term) or (sdtm_ct.codedvaluencicode = ct_vlm.assigned_term)) and 
        (not missing(ct_vlm.xmlcodelist))
  ;
quit;

%cst_setStandardProperties(_cstStandard=CST-FRAMEWORK,_cstSubType=initialize);
%cst_createdsfromtemplate(
  _cstStandard=CDISC-DEFINE-XML,_cstStandardVersion=2.1,
  _cstType=studymetadata,_cstSubType=codelist,_cstOutputDS=work.source_codelist_template
  );

%let _cstStudyVersion=;
%let _cstStandard=;
%let _cstStandardVersion=;
proc sql noprint;
 select StudyVersion, Standard, StandardVersion into :_cstStudyVersion, :_cstStandard, :_cstStandardVersion separated by ', '
 from metadata.source_study;
quit;

data work.source_codelists_sdtm(drop=datasetSpecializationId column shortname subsetcodelist term__ );
  set work.source_codelist_template work.source_codelists_sdtm(drop=codelist rename=(xmlcodelist__=codelist));
  sasref="SRCDATA";
  studyversion="&_cstStudyVersion";
  standard="&_cstStandard";
  standardversion="&_cstStandardVersion";
  codelistdatatype="text";
  if index(codelist, '_ORU_') or column="VSORRESU" then codelistname = catx(' ', cats(codelistname, ","),  "subset for", shortname, "-", "Original");
  if index(codelist, '_STU_') or column="VSSTRESU" then codelistname = catx(' ', cats(codelistname, ","),  "subset for", shortname, "-", "Standardized");
  
  if index(codelist, "TESTCD") or index(codelist, "NY")
     then do;
    if not missing(code_synonym) then decodetext = code_synonym;
                                 else decodetext = codedvaluechar;
  end;
  else decodetext="";
run;

proc sort data=work.source_codelists_sdtm out=data.source_codelists_sdtm NODUPRECS;
  by _ALL_;
run;  

ods listing close;
ods html5 file="&project_folder/data/source_codelists_sdtm.html";
ods excel file="&project_folder/data/source_codelists_sdtm.xlsx" options(sheet_name="CT" flow="tables" autofilter = 'all');

  proc print data=data.source_codelists_sdtm;
  run;  
  
ods excel close;
ods html5 close;
ods listing;


