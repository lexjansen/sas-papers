%if %symexist(_debug)=0 %then %do;
  %global _debug;
  %let _debug=0;
%end;  

options sasautos=(sasautos "&project_folder/macros");
options nomprint nomlogic nosymbolgen;

filename luapath ("&project_folder/lua");
 
%* This file contains the credentials;
%let credentials_file=&project_folder/programs/credentials.cfg;

%if %sysfunc(find(&sysscp,WIN)) %then %do;
  %let rest_proxyhost=;
  %let rest_proxyport=;
%end;
%if %sysfunc(find(&sysscp,LIN)) %then %do;
  %let rest_proxyhost=%str(webproxy.vsp.sas.com);
  %let rest_proxyport=3128;
%end;
%let rest_timeout=30;
%let rest_debug=%str(OUTPUT_TEXT NO_REQUEST_HEADERS NO_REQUEST_BODY NO_RESPONSE_HEADERS NO_RESPONSE_BODY);
/* These options need SAS 9.4M5. Set empty with earlier versions */
/*
%let rest_timeout=;
%let rest_debug=;
*/

%let base_url=https://library.cdisc.org/api;

%let working_folder=%sysfunc(pathname(work));
%let extract_folder=&project_folder/extract;
%let response_folder=&project_folder/response_json;
%let templates_folder=&project_folder/templates;

%let lsafadam_folder=&project_folder/lsaf/adam;
%let lsafcdash_folder=&project_folder/lsaf/cdash;
%let lsafsdtm_folder=&project_folder/lsaf/sdtm;
%let lsafsend_folder=&project_folder/lsaf/send;
%let lsafct_folder=&project_folder/lsaf/ct;

%let mapping_file=&project_folder/maps/mapping.xlsx;

libname tmplts  "&project_folder/templates";
libname maps  "&project_folder/maps";

libname prod "&extract_folder";

libname adam "&lsafadam_folder";
libname adamig "&lsafadam_folder";
libname cdash "&lsafcdash_folder";
libname cdashig "&lsafcdash_folder";
libname sdtm "&lsafsdtm_folder";
libname sdtmig "&lsafsdtm_folder";
libname send "&lsafsend_folder";
libname sendig "&lsafsend_folder";
libname ct "&lsafct_folder";

