%macro get_sdtm_specializations(package);

  filename jsonfile "%sysfunc(pathname(work))/dataspecializations_&package..json";

  %get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/specializations/sdtm/packages/&package/datasetspecializations,
    response_fileref=jsonfile
  );

  filename mapfile "%sysfunc(pathname(work))/dataspecialization.map";
  libname jsonfile json map=mapfile automap=create fileref=jsonfile noalldata ordinalcount=none;

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
%get_api_response(
    baseurl=&base_url,
    endpoint=/mdr/specializations/sdtm/packages,
    response_fileref=jsonf
  );
  
filename mpfile "%sysfunc(pathname(work))/package.map";
libname jsonf json map=mpfile automap=create fileref=jsonf noalldata ordinalcount=none;

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

data work.latest_sdtm;
  set __sdtm;
  by datasetSpecializationId latest_package_date;
  if last.datasetSpecializationId;
run;  

data _null_;
  set work.latest_sdtm;
  length code $4096 response_file $1024;
  baseurl="&base_url";
  response_file=cats("&project_folder/json/sdtm/", datasetSpecializationId, ".json");
  response_file=lowcase(response_file);
  code=cats('%get_api_response(baseurl=', baseurl, ', endpoint=', href, ', response_file=', response_file, ');');
  call execute (code);
run;

%put %sysfunc(dcreate(jsontmp, %sysfunc(pathname(work))));
libname jsontmp "%sysfunc(pathname(work))/jsontmp";
* libname jsontmp "&project_folder/_temp";

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

libname jsontmp clear;

/*********************************************************************************************************************/
/* fix some issues                                                                                                   */
/*********************************************************************************************************************/
data work.sdtm_specializations;
  set work.sdtm__:;
  
  /* xxTEST variables shoukd not be used in the whereclauses */
  if length(name) >= 4 and substr(name, length(name)-3, 4) = "TEST" and (not missing(comparator)) then do;
    putlog 'WAR' 'NING: ' datasetSpecializationId= name= comparator=;
    comparator="";
  end;  
  
  /* Variables should only be used in an EQ whereclause whwn they have an asssigned_value */
  if (not missing(comparator)) and comparator = "EQ" and missing(assigned_value) then do;
    putlog 'WAR' 'NING: ' datasetSpecializationId= name= comparator= assigned_value=;
    comparator="";    
  end;
  /* Variables should only be used in an IN whereclause whwn they have an value_list */
  if (not missing(comparator)) and comparator = "IN" and missing(value_list) then do;
    putlog 'WAR' 'NING: ' datasetSpecializationId= name= comparator= value_list=;
    comparator="";
  end;
  /* Variables should be used either in a whereclause or be a VLM target */
  if (not missing(comparator)) and (not missing(vlmTarget)) then do;
    putlog 'WAR' 'NING: ' datasetSpecializationId= name= comparator= vlmTarget=;
  end;
  
  if datasetSpecializationId = "CARBXHGB" and name = "LBSTRESU" and missing(assigned_value) then assigned_value="g/dL";
  if datasetSpecializationId = "BMI" and name = "VSSTRESU" and missing(assigned_value) then assigned_value = "kg/m2";
  if datasetSpecializationId = "HEIGHT" and name = "VSSTRESU" and missing(assigned_value) then assigned_value = "cm";
  if datasetSpecializationId = "WEIGHT" and name = "VSSTRESU" and missing(assigned_value) then assigned_value = "kg";
  if datasetSpecializationId = "TEMP" and name = "VSSTRESU" and missing(assigned_value) then assigned_value = "C";
  if datasetSpecializationId = "WSTCIR" and name = "VSSTRESU" and missing(assigned_value) then assigned_value = "cm";
  
  if index(value_list, "COROTID ARTERY") then value_list = tranwrd(value_list, "COROTID ARTERY", "CAROTID ARTERY");
  if index(value_list, "RADIAL ARTERY")=0 then value_list = tranwrd(value_list, "RADIAL ARTER", "RADIAL ARTERY");
  if assigned_value="mmHG" then assigned_value="mmHg";
  
  if datasetSpecializationId = "FRMSIZE" and name="VSSTRESC" and missing(value_list) then value_list="SMALL;MEDIUM;LARGE";
  
  if codelist_submission_value="VSTESTCD" then codelist="C66741";
  if codelist_submission_value="VSTEST" then codelist="C67153";
run;
/*********************************************************************************************************************/
/*********************************************************************************************************************/

proc sort data=sdtm_specializations out=data.sdtm_specializations;
  by datasetSpecializationId order;
run;  

ods listing close;
ods html5 file="&project_folder/data/sdtm_specializations.html";
ods excel options(sheet_name="SDTM_DatasetSpecializations" flow="tables" autofilter = 'all') file="&project_folder/data/sdtm_specializations.xlsx";

  title "SDTM Specializations (generated on %sysfunc(datetime(), is8601dt.))";
  proc report data=data.sdtm_specializations;
    columns packageDate biomedicalConceptId dataElementConceptId sdtmigStartVersion sdtmigEndVersion domain source datasetSpecializationId
            shortName name order isNonStandard codelist_href codelist codelist_submission_value subsetCodelist
            value_list assigned_term assigned_value role subject linkingPhrase predicateTerm object 
            dataType length format significantDigits mandatoryVariable mandatoryValue originType originSource comparator vlmTarget;
    
    define codelist_href / noprint; 
               
    compute dataElementConceptId;
      if not missing(dataElementConceptId) then do;
        call define (_col_, 'url', cats('https://ncithesaurus.nci.nih.gov/ncitbrowser/ConceptReport.jsp?dictionary=NCI_Thesaurus&ns=ncit&code=', dataElementConceptId));
        call define (_col_, "style","style={textdecoration=underline color=#0000FF}");
      end;  
    endcomp;

    compute codelist;
      if not missing(codelist) then do;
        call define (_col_, 'url', codelist_href);
        call define (_col_, "style","style={textdecoration=underline color=#0000FF}");
      end;  
    endcomp;
  run;

ods html5 close;
ods excel close;
ods listing;
