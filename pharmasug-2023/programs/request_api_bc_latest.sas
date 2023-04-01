%macro get_bc(package);

  filename jsonfile "&project_folder/json/biomedicalconcepts_&package..json";
  filename mapfile "%sysfunc(pathname(work))/bc.map";
  libname jsonfile json map=mapfile automap=create fileref=jsonfile noalldata ordinalcount=none;

  %get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/bc/packages/&package/biomedicalconcepts,
    response_fileref=jsonfile
  );

  data __bc;
    length biomedicalConceptId $64 latest_package_date $10 href title $1024;
    set __bc jsonfile._links_biomedicalconcepts;
    biomedicalConceptId=scan(href, -1, "\/");
    latest_package_date=scan(href, -3, "\/");
  run;  

  filename jsonfile clear;
  libname jsonfile clear;
  filename mapfile clear;
  
%mend get_bc;  


/*************************************************************************************************/

%global project_folder;
%let project_folder=/_github/lexjansen/sas-papers/pharmasug-2023;
%* Generic configuration;
%include "&project_folder/programs/config.sas";

data __bc;
  if 0=1;
run;  

filename jsonf "&project_folder/json/biomedicalconcept_packages.json";
filename mpfile "%sysfunc(pathname(work))/package.map";
libname jsonf json map=mpfile automap=create fileref=jsonf noalldata ordinalcount=none;

%get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/bc/packages,
    response_fileref=jsonf
  );

data _null_;
  set jsonf._links_packages;
  length code $4096 package $32;
  package=scan(href, -2, "\/");
  code=cats('%get_bc(package=', package, ');');
  call execute (code);
run;

filename jsonf clear;
libname jsonf clear;
filename mpfile clear;

proc sort data=__bc;
  by biomedicalConceptId latest_package_date;
run;

data data.latest_bc;
  set __bc;
  by biomedicalConceptId latest_package_date;
  if last.biomedicalConceptId;
run;  

data _null_;
  set data.latest_bc;
  length code $4096 response_file $1024;
  baseurl="&base_url";
  response_file=cats("&project_folder/json/bc/", biomedicalConceptId, ".json");
  response_file=lowcase(response_file);
  code=cats('%get_api_response(baseurl=', baseurl, ', endpoint=', href, ', response_file=', response_file, ');');
  call execute (code);
run;

