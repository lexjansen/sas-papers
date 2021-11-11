%global root;
%let root=/_projects/sas-papers/phuse_eu-2021;

filename luapath "&root/lua";

filename jsonfile "&root/json/example1.json";
libname jsonfile json fileref=jsonfile noalldata;

proc copy in=jsonfile out=work;
run;

libname jsonfile clear;
filename jsonfile clear;


filename map "&root/programs/example1_map.json";
filename jsonfile "&root/json/example1.json";
libname jsonfile json map=map automap=reuse fileref=jsonfile noalldata;

proc copy in=jsonfile out=work;
run;

proc sql;
  /* concatenate all synonyms* variable names*/
  select cats("s.", name) into :synonym_variables separated by "," 
    from dictionary.columns
    where libname = "WORK" and memname eq "TERMS_SYNONYMS" and 
      index(upcase(name), "SYNONYMS") and type eq "char";
  
  create table work.codelist_terms_synonyms
    as select 
      c.name as codelist_name,
      c.submissionValue as codelist_submissionValue,
      c.definition as codelist_definition,
      c.conceptId as codelist_conceptId,
      c.preferredTerm as codelist_preferredTerm,
      ifc(c.extensible = "true", "Yes", "No", "") as extensible,   
      t.submissionValue as term_submissionValue,
      t.conceptId as term_conceptId,
      catx('; ', &synonym_variables) as synonyms,
      t.definition as term_definition,
      t.preferredTerm as term_preferredTerm
    from work.codelists c
  left join work.codelists_terms t
    on t.ordinal_codelists = c.ordinal_codelists
  left join work.terms_synonyms s
    on s.ordinal_terms = t.ordinal_terms;
quit;    
