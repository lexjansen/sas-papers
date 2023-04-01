%macro get_sdtm_specializations(package);

  filename jsonfile "&project_folder/json/dataspecializations_&package..json";
  filename mapfile "%sysfunc(pathname(work))/dataspecialization.map";
  libname jsonfile json map=mapfile automap=create fileref=jsonfile noalldata ordinalcount=none;

  %get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/specializations/sdtm/packages/&package/datasetspecializations,
    response_fileref=jsonfile
  );

  data __sdtm;
    length datasetSpecializationId $64 latest_package_date $10 href title $1024;
    set __sdtm jsonfile._links_datasetspecializations;
    datasetSpecializationId=scan(href, -1, "\/");
    latest_package_date=scan(href, -3, "\/");
  run;  

  filename jsonfile clear;
  libname jsonfile clear;
  filename mapfile clear;
  
%mend get_sdtm_specializations;  


/*************************************************************************************************/

%global project_folder;
%let project_folder=/_github/lexjansen/sas-papers/pharmasug-2023;
%* Generic configuration;
%include "&project_folder/programs/config.sas";

filename jsonf "&project_folder/json/datasetspecializations_packages.json";
filename mpfile "%sysfunc(pathname(work))/package.map";
libname jsonf json map=mpfile automap=create fileref=jsonf noalldata ordinalcount=none;

%get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/specializations/sdtm/packages,
    response_fileref=jsonf
  );

data __sdtm;
  if 0=1;
run;  

data _null_;
  set jsonf._links_packages;
  length code $4096 package $32;
  package=scan(href, -2, "\/");
  code=cats('%get_sdtm_specializations(package=', package, ');');
  call execute (code);
run;

filename jsonf clear;
libname jsonf clear;
filename mpfile clear;


proc sort data=__sdtm;
  by datasetSpecializationId latest_package_date;
run;


data data.latest_sdtm;
  set __sdtm;
  by datasetSpecializationId latest_package_date;
  if last.datasetSpecializationId;
run;  

data _null_;
  set data.latest_sdtm;
  length code $4096 response_file $1024;
  baseurl="&base_url";
  response_file=cats("&project_folder/json/sdtm/", datasetSpecializationId, ".json");
  response_file=lowcase(response_file);
  code=cats('%get_api_response(baseurl=', baseurl, ', endpoint=', href, ', response_file=', response_file, ');');
  call execute (code);
run;


%put %sysfunc(dcreate(jsontmp, %sysfunc(pathname(work))));
libname jsontmp "%sysfunc(pathname(work))/jsontmp";

%create_template(type=sdtm, out=work.sdtm__template);

data _null_;
  length fref $8 name $64 jsonpath $200 code $400;
  did = filename(fref,"&project_folder/json/sdtm");
  did = dopen(fref);
  if did ne 0 then do;
    do i = 1 to dnum(did);
      if index(dread(did,i), "json") then do;
        name=scan(dread(did,i), 1, ".");
        jsonpath=cats("&project_folder/json/sdtm/", name, ".json");
        code=cats('%nrstr(%read_sdtm_from_json(',
                            'json_path=', jsonpath, ', ',
                            'out=work.sdtm__', name, ', ', 
                            'jsonlib=jsontmp, ',
                            'template=work.sdtm__template',
                          ');)');
        call execute(code);
      end;
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;

data data.sdtm_specializations;
  set work.sdtm__:;
run;
