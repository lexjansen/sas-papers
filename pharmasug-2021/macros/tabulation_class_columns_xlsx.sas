%macro tabulation_class_columns_xlsx(
  ExcelFile=, 
  Sheet=Variables,
  DSOut=, 
  DSCompare=,
  Template=tmplts.tabulation_columnclass, 
  debug=0,
  comparedrop=%str(drop=codelistreference columnreferenceformat)
  );

  %read_excel(
    XLFile=&ExcelFile,
    XLSheet=&Sheet, 
    XLDSName=&DSOut
    );

  %if &debug %then %do;
    proc contents data=&DSOut varnum;
    proc print data=&DSOut(obs=10);
    run;  
  %end;
  
  data &DSOut(DROP=Variable_Order);
    length order 8.;
    set &Template &DSOut(
        rename=(
        Variable_Name=name
        Class=columngroupname
        description=columnreferencenote
        Variable_Label=description
        Controlled_Terms__Codelist_or_Fo=codelistreference
        type=submissiondatatype
      ));
      order = input(variable_order, best.);
run;

  proc sort data=&DSOut;
    by DATASET_NAME COLUMNGROUPNAME ORDER;
  run;          

  %if %sysfunc(exist(&DSCompare)) %then %do;
    
    proc sort data=&DSCompare 
              out=work.%scan(&DSCompare, 2, %str(.))_json;
      by DATASET_NAME COLUMNGROUPNAME ORDER;
    run;    

    title01 "ExcelFile = &ExcelFile";
    proc compare base=work.%scan(&DSCompare, 2, %str(.))_json(&comparedrop) 
                 compare=&DSOut(&comparedrop) 
                 listall;
      id DATASET_NAME COLUMNGROUPNAME ORDER;
    run;  
    
    %put WAR%str(NING): &=sysinfo [&ExcelFile];  
    
  %end;
  %else %do;
    %put WAR%str(NING): &DSCompare can not be found.;
  %end;

%mend tabulation_class_columns_xlsx; 
