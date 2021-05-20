%macro map_extract_to_lsaf(
  mappingds=,
  tabletype=,
  template=,
  source=,
  target=,
  where=,
  debug=0
  );

%local drop_columns rename_columns assign_columns extension;
%let drop_columns=;
%let rename_columns=;
%let assign_columns=;

data &mappingds;
 set &mappingds;
  where not(missing(table));
run;

proc sql noprint;
  select source into :drop_columns separated by ' '
  from &mappingds
  where (upcase(table)=upcase("&tabletype")) and (action="DROP")
  ;
  select cats(source, "=", target) into :rename_columns separated by ' '
  from &mappingds
  where (upcase(table)=upcase("&tabletype")) and (action="RENAME") and (source ne target)
  ;
  select cats(target, "=", value, ";") into :assign_columns separated by ' '
  from &mappingds
  where (upcase(table)=upcase("&tabletype")) and (action="ASSIGN") and (not missing(value))
  ;
quit;

%if &debug=1 %then %do;
  %put drop=&drop_columns;
  %put rename=(&rename_columns);
  %put %nrbquote(&assign_columns);
%end;

data &target;
  set &source;
  &where;
  %if %sysevalf(%superq(assign_columns)=, boolean)=0 %then &assign_columns;
  %if %sysevalf(%superq(drop_columns)=, boolean)=0 %then drop &drop_columns;;
  %if %sysevalf(%superq(rename_columns)=, boolean)=0 %then rename &rename_columns;;
run;  

data &target;
  set &template &target;
run;  

proc sort data=&target;
  %if &tabletype=columnclassgroup %then by name;
  %if &tabletype=columnclass %then by dataset_name columngroupname order;
  %if &tabletype=table %then by order;
  %if &tabletype=column %then by tablename order;
  %if &tabletype=codelist %then by codelist_shortname coded_value;
  ;
run;  

%mend map_extract_to_lsaf;
