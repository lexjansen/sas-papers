%global root;
%let root=/_projects/sas-papers/phuse_eu-2021;

filename luapath "&root/lua";

proc lua restart;
submit;

  hours_synonyms = {'Hours', 'hr', 'h'}   -- simple array
  
  for i, synonym in ipairs(hours_synonyms) do
    print(i, synonym)
  end 

  terms = {}  -- associative array
  terms.conceptId = "C25529"
  terms.definition = "Terminology Codelist used for units within CDISC"
  terms.name = "Unit" 
  terms.preferredTerm = "CDISC SDTM Unit of Measure Terminology"
  terms.submissionValue = "UNIT"
  terms.synonyms = hours_synonyms 
  terms.extendedValue = false
  
  print(table.tostring(terms))

  for key, value in pairs(terms) do
    print(key, value)
  end

  print(table.tostring(terms.synonyms))

endsubmit;
run;
