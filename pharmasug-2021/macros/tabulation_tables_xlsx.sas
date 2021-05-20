%macro tabulation_tables_xlsx(
  ExcelFile=, 
  Sheet=Datasets,
  DSOut=, 
  DSCompare=, 
  Template=tmplts.tabulation_table, 
  debug=0,
  comparedrop=%str(drop=order purpose tablereferencenote)
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
  
  data &DSOut();
    ;
    set &Template &DSOut(
        rename=(
        Dataset_Name=Name
        Dataset_Label=Description
      ));
run;

  proc sort data=&DSOut;
    by NAME;
  run;          

  %if %sysfunc(exist(&DSCompare)) %then %do;
    
    proc sort data=&DSCompare 
              out=work.%scan(&DSCompare, 2, %str(.))_json;
      by NAME;
    run;    

    title01 "ExcelFile = &ExcelFile";
    proc compare base=work.%scan(&DSCompare, 2, %str(.))_json(&comparedrop) 
                 compare=&DSOut(&comparedrop) 
                 listall;
      id NAME;
    run;  
    
    %put WAR%str(NING): &=sysinfo [&ExcelFile];  
    
  %end;
  %else %do;
    %put WAR%str(NING): &DSCompare can not be found.;
  %end;

%mend tabulation_tables_xlsx; 
