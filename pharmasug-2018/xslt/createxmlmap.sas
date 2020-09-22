%macro CreateXMLMap(library=, metadatadataset=, tablepath=, tablename=, mapfileref=);
  
    proc sql noprint;
      create table work.__attributes as
      select memname as table, strip(name) as name, strip(label) as label, type, length
      from dictionary.columns
      where (upcase(libname)=%upcase("&library") and upcase(memname)=%upcase("&metadatadataset"))
      order by varnum
      ;
    quit;

    data _null_;
      length element $400 numval dtype ddtype $10;
      set work.__attributes END=eof;
      file &mapfileref;
      by table;
      if _n_ = 1 then do;
        put '<?xml version="1.0" encoding="UTF-8"?>';
        put '<SXLEMAP name="define" version="2.1">';
      end;

      dtype = ifc(upcase(type)="CHAR", "character", "numeric");
      ddtype = ifc(upcase(type)="CHAR", "string", "integer");
      numval = strip(input(length, best12.));

      if first.table then do;
         put '<TABLE name="' "&tablename" '">';
         put '<TABLE-PATH syntax="XPath">/' "&tablepath" '</TABLE-PATH>';
      end;
      
      element=catt('<COLUMN name="', name, '">');
      put element;
      element=catt('<PATH syntax="XPath">/', "&tablepath", "/", name, '</PATH>');
      put element;
      element=catt('<TYPE>',dtype,'</TYPE>');
      put element;
      element=catt('<DATATYPE>', ddtype, '</DATATYPE>');
      put element;
      element=catt('<DESCRIPTION>', label, '</DESCRIPTION>');
      put element;
      element=catt('<LENGTH>', numval, '</LENGTH>');
      put element;
      put '</COLUMN>';

      if last.table then put "</TABLE>";
      if eof then put "</SXLEMAP>";
    run;
    
%mend CreateXMLMap;


