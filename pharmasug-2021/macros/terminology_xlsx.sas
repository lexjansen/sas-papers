%macro terminology_xlsx(
  ExcelFile=, 
  Sheet=Terminology,
  DSOut=, 
  DSCompare=, 
  Template=tmplts.terminology, 
  ReleaseDate=, 
  debug=0, 
  comparedrop=%str(drop=description)
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
  
  data &DSOut(drop=VAR3 CDISC_Synonym_s_ CDISC_Definition NCI_Preferred_Term);
    attrib CODELIST_SHORTNAME length=$70;
    attrib CODELIST_EXTENSIBLE length=$3;
    attrib CODELIST_DESCRIPTION length=$1024;
    attrib CODELIST_PREFERRED_TERM length=$200;
    ;
    retain CODELIST_SHORTNAME CODELIST_DESCRIPTION CODELIST_EXTENSIBLE CODELIST_PREFERRED_TERM;
    set &Template &DSOut(
      rename=(
        CDISC_Submission_Value=CODED_VALUE
        Standard_and_Date=NAME
        ));
    if not missing(VAR3) then do;
      CODELIST_EXTENSIBLE=VAR3;
      CODELIST_SHORTNAME=CODED_VALUE;
      CODELIST_CODE=CODE;
      CODELIST_DESCRIPTION=CDISC_Definition;
      CODELIST_PREFERRED_TERM=NCI_Preferred_Term;
      delete;
    end;
    source="NCI Thesaurus";
    RELEASEDATE="&ReleaseDate";
    SOURCEVERSION="&ReleaseDate";
    CODELIST_DATATYPE="text";
    CODELIST_EXTENSIBLE_STUDY=CODELIST_EXTENSIBLE;
    CODELIST_SUBSETTABLE="Yes";
    PREFERRED_TERM=NCI_Preferred_Term;
    SYNONYMS=CDISC_synonym_s_;
    DEFINITION=CDISC_Definition;
  run;
  
  data &DSOut;
    set &Template &DSOut;
  run;  
  
  proc sort data=&DSOut;
    by CODELIST_SHORTNAME CODED_VALUE;
  run;          

  %if %sysfunc(exist(&DSCompare)) %then %do;
    
    proc sort data=&DSCompare 
              out=work.%scan(&DSCompare, 2, %str(.))_json;
      by CODELIST_SHORTNAME CODED_VALUE;
    run;    

    title01 "ExcelFile = &ExcelFile";
    proc compare base=work.%scan(&DSCompare, 2, %str(.))_json(&comparedrop) 
                 compare=&DSOut(&comparedrop) 
                 listall;
      id CODELIST_SHORTNAME CODED_VALUE;
    run;    
    
    %put WAR%str(NING): &=sysinfo [&ExcelFile];  

  %end;
  %else %do;
    %put WAR%str(NING): &DSCompare can not be found.;
  %end;

%mend terminology_xlsx; 
