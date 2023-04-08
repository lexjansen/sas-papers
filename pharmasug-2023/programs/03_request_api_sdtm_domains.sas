%global project_folder;
%let project_folder=c:/_github/lexjansen/sas-papers/pharmasug-2023;
%* Generic configuration;
%include "&project_folder/programs/config.sas";

*******************************************************************************;
* Get CDISC LIbrary SDTM CT package                                           *;
*******************************************************************************;

%macro get_domain(domain=, version=);

  filename jsonf "&project_folder/json/sdtmig_&version.-%lowcase(&domain).json";

  %if not %sysfunc(fileexist(%sysfunc(pathname(jsonf)))) %then %do;
    %get_api_response(
      baseurl=&base_url,
      endpoint=/mdr/sdtmig/&version/datasets/%upcase(&domain),
      response_fileref=jsonf
    );
  %end;

  filename mpfile "%sysfunc(pathname(work))/package.map";
  libname jsonf json map=mpfile automap=create fileref=jsonf noalldata;

  %put %sysfunc(dcreate(jsontmp, %sysfunc(pathname(work))));
  libname jsontmp "%sysfunc(pathname(work))/jsontmp";
  * libname jsontmp "&project_folder/_temp/&domain";

  proc datasets library=jsontmp kill nolist;
  quit;

  proc copy in=jsonf out=jsontmp;
  run; 

  filename jsonf clear;
  filename mpfile clear;
  libname jsonf clear;
  libname jsontmp clear;

%mend get_domain;

%let _cstCDISCStandardVersion=;
proc sql noprint;
 select CDISCStandardVersion into :_cstCDISCStandardVersion separated by ', '
 from metadata.source_standards
 where type = "IG" and 	cdiscstandard = "SDTMIG"
 ;
quit;
%let _cstCDISCStandardVersion = %sysfunc(translate(&_cstCDISCStandardVersion, %str(-), %str(.)));
%put &=_cstCDISCStandardVersion;

%get_domain(domain=lb, version=&_cstCDISCStandardVersion);
%get_domain(domain=vs, version=&_cstCDISCStandardVersion);
