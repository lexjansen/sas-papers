%macro tabulation_columns_xlsx(
  ExcelFile=, 
  Sheet=Variables,
  DSOut=, 
  DSCompare=, 
  Template=tmplts.tabulation_column, 
  debug=0,
  comparedrop=%str(drop=classcolumn codelistreference columnreferenceformat)
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
    length order 8.;
    set &Template &DSOut(
        rename=(
        Dataset_Name=tablename
        Variable_Name=name
        Variable_Label=description
        Controlled_Terms__Codelist_or_Fo=codelistreference
        type=submissiondatatype
        CDISC_Notes=columnreferencenote
      ));
      order = input(variable_order, best.);
run;

  proc sort data=&DSOut;
    by TABLENAME NAME;
  run;          

  %if %sysfunc(exist(&DSCompare)) %then %do;
    
    proc sort data=&DSCompare 
              out=work.%scan(&DSCompare, 2, %str(.))_json;
      by TABLENAME NAME;
    run;    

    title01 "ExcelFile = &ExcelFile";
    proc compare base=work.%scan(&DSCompare, 2, %str(.))_json(&comparedrop) 
                 compare=&DSOut(&comparedrop) 
                 listall;
      id TABLENAME NAME;
    run;  
    
    %put WAR%str(NING): &=sysinfo [&ExcelFile];  
    
  %end;
  %else %do;
    %put WAR%str(NING): &DSCompare can not be found.;
  %end;

%mend tabulation_columns_xlsx; 
