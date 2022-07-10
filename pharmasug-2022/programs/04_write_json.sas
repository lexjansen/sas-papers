%macro process(dataset, model);
  %local dataset_name dataset_label records 
    studyOID metaDataVersionOID
    ClinicalReferenceData ItemGroupOID;

  %let dataset_name=%scan(&dataset, -1, %str(.));
  %let dataset_label=;
  %let ItemGroupOID=;
  %let studyOID=;
  %let metaDataVersionOID=;

  %if %utl_varexist(&dataset, usubjid) %then
      %let ClinicalReferenceData=clinicalData;
    %else %let ClinicalReferenceData=referenceData;

  %let records=%utl_nobs(&dataset);

  libname metadata "&root/metadata/&model";

  /* Get StudyOID and metaDataVersionOID */
  proc sql noprint;
    select studyOID, metaDataVersionOID into :studyOID trimmed, :metaDataVersionOID trimmed
      from metadata.metadata_study;
  /* Get dataset label and ItemGroupOID */
    select label, oid into :dataset_label, :ItemGroupOID trimmed
      from metadata.metadata_tables
        where upcase(name)="%upcase(&dataset_name)";
  quit;
  
  %put ### &=dataset &=records &=ClinicalReferenceData &=ItemGroupOID dslabel=%bquote(&dataset_label);

  data work.column_metadata(keep=OID name label type length);
    retain OID name label type length;
    set metadata.metadata_columns(
      rename=(json_datatype=type)
      where=(upcase(dataset_name) = %upcase("&dataset_name")));
  run;

  /* Create a 1-obs dataset with the same structure as the column_metadata dataset */
  proc sql noprint;
    create table itemgroupdataseq
      like work.column_metadata;
    insert into itemgroupdataseq
      set OID="ITEMGROUPDATASEQ", name="ITEMGROUPDATASEQ", label="Record Identifier",
        type="integer";
  quit;

  data work.column_metadata;
    set itemgroupdataseq work.column_metadata;
  run;
  
  %******************************************************************************;
  data work.column_data;
    length ITEMGROUPDATASEQ 8.;
    set &dataset;
    ITEMGROUPDATASEQ = _n_;
  run;

  filename jsonfout "&root/json_out/&model/&dataset_name..json";

  PROC JSON OUT=jsonfout NOPRETTY NOSASTAGS SCAN TRIMBLANKS
                         NOFMTCHARACTER NOFMTDATETIME NOFMTNUMERIC;
    WRITE OPEN OBJECT;
    WRITE VALUES "&ClinicalReferenceData";
    WRITE OPEN OBJECT;
    WRITE VALUES "studyOID" "&studyOID";
    WRITE VALUES "metaDataVersionOID" "&metaDataVersionOID";
    WRITE VALUE "itemGroupData";
    WRITE OPEN OBJECT;
    WRITE VALUE "&ItemGroupOID";
    WRITE OPEN OBJECT;
    WRITE VALUES "records" &records;
    WRITE VALUES "name" "%upcase(&dataset_name)";
    WRITE VALUES "label" "&dataset_label";

    WRITE VALUE "items";
    %write_json_metadata_array(work.column_metadata);
    WRITE CLOSE;

    WRITE VALUE "itemData";
    WRITE OPEN ARRAY;
    EXPORT work.column_data / NOKEYS;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
    WRITE CLOSE;
  RUN;

  filename jsonfout clear;
  libname metadata clear;

  proc delete data=work.column_metadata;
  run;

  proc delete data=work.column_data;
  run;

%mend process;

%let root=/_github/lexjansen/sas-papers/pharmasug-2022;
%include "&root/programs/config.sas";



%let model=adam;
libname data "&root/data/&model";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

data _null_;
  length code $200;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%process(data.', name, ", &model);)");
  call execute(code);
run;
libname data clear;
  

%let model=sdtm;
libname data "&root/data/&model";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

data _null_;
  length code $200;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%process(data.', name, ", &model);)");
  call execute(code);
run;
libname data clear;
