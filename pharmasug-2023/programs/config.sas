%if %symexist(_debug)=0 %then %do;
  %global _debug;
  %let _debug=0;
%end;  

options sasautos = ("&project_folder/macros", %sysfunc(compress(%sysfunc(getoption(sasautos)),%str(%(%)))));
options nomprint nomlogic nosymbolgen;

%* This file contains the credentials;
%*let credentials_file=&project_folder/programs/credentials.cfg;

%*read_config_file(
  config_file=&credentials_file, 
  sections=%str("cdisclibrary")
);

%read_config_file(
  config_file=%sysget(CREDENTIALS_FILE), 
  sections=%str("cdisclibrary")
);

%let api_key=&cdisc_api_primary_key;
%let rest_debug=%str(OUTPUT_TEXT NO_REQUEST_HEADERS NO_REQUEST_BODY RESPONSE_HEADERS NO_RESPONSE_BODY);
%let base_url=https://library.cdisc.org/api;
%let base_url_cosmos=&base_url/cosmos/v2;

libname data "&project_folder/data";
libname metadata "&project_folder/metadata";

