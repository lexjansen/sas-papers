%global project_folder;
%let project_folder=c:/_github/lexjansen/sas-papers/pharmasug-2023;
%* Generic configuration;
%include "&project_folder/programs/config.sas";

*******************************************************************************;
* Get CDISC LIbrary SDTM CT package                                           *;
*******************************************************************************;

%let _cstCDISCStandardVersion=;
proc sql noprint;
 select CDISCStandardVersion into :_cstCDISCStandardVersion separated by ', '
 from metadata.source_standards
 where type = "CT" and 	cdiscstandard = "CDISC/NCI" and publishingSet = "SDTM"
 ;
quit;
%put &=_cstCDISCStandardVersion;

filename jsonf "&project_folder/json/sdtmct-&_cstCDISCStandardVersion..json";

%if not %sysfunc(fileexist(%sysfunc(pathname(jsonf)))) %then %do;
  %get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/ct/packages/sdtmct-&_cstCDISCStandardVersion,
    response_fileref=jsonf
  );
%end;

filename mpfile "%sysfunc(pathname(work))/package.map";
libname jsonf json map=mpfile automap=create fileref=jsonf noalldata;

%put %sysfunc(dcreate(jsontmp, %sysfunc(pathname(work))));
libname jsontmp "%sysfunc(pathname(work))/jsontmp";
* libname jsontmp "&project_folder/_temp";

proc datasets library=jsontmp kill nolist;
quit;

proc copy in=jsonf out=jsontmp;
run; 

proc sql;
  create table data.sdtm_ct as
  select 
    cl.submissionvalue as codelist,
    cl.name as codelistname,
    cl.conceptid as codelistncicode,
    clt.conceptid as codedvaluencicode,
    clt.submissionvalue as codedvaluechar,
    clts.synonyms1 as code_synonym,
    "CDISC/NCI" as cdiscstandard,
    root.version as cdiscstandardversion,
    scan(root.name, 1, " ") as publishingset
  from jsontmp.root root
    left join jsontmp.codelists cl
  on (root.ordinal_root = cl.ordinal_root)
    left join jsontmp.codelists_terms clt 
  on (cl.ordinal_codelists = clt.ordinal_codelists)
    left join jsontmp.terms_synonyms clts 
  on (clt.ordinal_terms = clts.ordinal_terms)
  order by codelist, codedvaluechar
  ;
quit;  

filename jsonf clear;
filename mpfile clear;
libname jsonf clear;
libname jsontmp clear;
