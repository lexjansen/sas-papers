%macro tabulation_class_tables_xlsx(
  ExcelFile=, 
  Sheet=Datasets,
  DSOut=, 
  DSCompare=, 
  Template=tmplts.tabulation_columnclassgroup, 
  debug=0,
  comparedrop=%str(drop=TABLEREFERENCENOTE)
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
        Class=Name
        Dataset_Label=Description
        Structure=Class_Structure
      ));
run;

  proc sort data=&DSOut;
    by DESCRIPTION;
  run;          

  %if %sysfunc(exist(&DSCompare)) %then %do;
    
    proc sort data=&DSCompare 
              out=work.%scan(&DSCompare, 2, %str(.))_json;
      by DESCRIPTION;
    run;    

    title01 "ExcelFile = &ExcelFile";
    proc compare base=work.%scan(&DSCompare, 2, %str(.))_json(&comparedrop) 
                 compare=&DSOut(&comparedrop) 
                 listall;
      id DESCRIPTION;
    run;  
    
    %put WAR%str(NING): &=sysinfo [&ExcelFile];  
    
  %end;
  %else %do;
    %put WAR%str(NING): &DSCompare can not be found.;
  %end;

%mend tabulation_class_tables_xlsx; 
