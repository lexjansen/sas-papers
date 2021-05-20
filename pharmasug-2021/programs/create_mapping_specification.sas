%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;




%* Generic configuration;
%include "&project_folder/programs/config.sas";

%read_excel(
  XLFile=&mapping_file,
  XLSheet=Mapping,
  XLDSName=maps.mapping
  );
