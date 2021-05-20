%macro read_excel(
  XLFile=,
  XLSheet=, 
  XLDSName=
  );

%local extension;
%let extension=%scan(&XLFile, -1);

%if %upcase(&extension) eq %str(XLSX) %then %do;
  proc import datafile="&XLFile" out=&XLDSName 
    dbms=xlsx replace;
    sheet="&XLSheet";
  run;
%end;

%if %upcase(&extension) eq %str(XLS) %then %do;
  proc import datafile="&XLFile" out=&XLDSName 
    dbms=xls replace;
    sheet="&XLSheet";
  run;
%end;

%if %upcase(&extension) eq %str(CSV) %then %do;
  proc import datafile="&XLFile" out=&XLDSName 
    dbms=csv replace;
    getnames=yes;
  run;
%end;

data &XLDSName;
 set &XLDSName;
  format _character_;
  informat _character_;
run;


%mend;


/*
libname mapping xlsx "&mapping_file";
data mapping2;
  set mapping.mapping;
  format _character_;
  informat _character_;
run;
*/