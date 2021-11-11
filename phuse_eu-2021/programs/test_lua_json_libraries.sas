%global root;
%let root=/_projects/sas-papers/phuse_eu-2021;

filename luapath ("&root/lua" "&root/lua/jsonlibraries");


proc lua restart;
  submit;

    fileutils = require "fileutils"
    rest = require 'rest'
    cdisclibrary = require 'cdisclibrary'

    example = "sdtmct_20210625"
    request = "/mdr/ct/packages/sdtmct-2021-06-25"

    json_file = sas.symget("root").."/json/"..example..".json"
    dataset_base = "out."..example
    
    sas.gfilename("jsonfile", json_file)
    sas.glibname("out", sas.symget("root").."/"..example)
    sas.filename("mapfile", sas.symget("root").."/"..example.."/"..example.."_map.json");
    
    rest.base_url = "https://library.cdisc.org/api"
    -- provide your own CDISC library API key
    local token = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    -- local token = fileutils.read_config('credentials.cfg').cdisclibrary.cdisc_api_primary_key
    rest.headers='"Accept"="application/json" "api-key"='..'"'..token..'"'
    rest.debug = "OUTPUT_TEXT NO_REQUEST_HEADERS NO_REQUEST_BODY RESPONSE_HEADERS NO_RESPONSE_BODY"
    rest.quiet=true
    
    if (not sas.fileexists(json_file)) then
      local pass,code = rest.request('get', request, 'jsonfile')
      if not pass then sas.io.delete(json_file) end
    end  
    
    sas.submit[[
      proc datasets library=out kill nolist nowarn;
      run;
      quit;    
    ]]

    print("      >>> creating template out.codelist_terms_synonyms\n")
    local dsid = cdisclibrary.create_codelist_template (dataset_base)
    sas.close(dsid)
    
   endsubmit;
run;

proc lua;
  submit;

   sas.submit[[
      libname jsonfile json map=mapfile automap=create fileref=jsonfile;
      proc copy in=jsonfile out=out;
      run;
      ]]

    sas.submit([[
      proc sql noprint;
        /* concatenate all synonyms* variable names*/
        select cats("s.", name) into :synonym_variables separated by "," 
          from dictionary.columns
          where libname = "OUT" and memname eq "TERMS_SYNONYMS" and 
            index(upcase(name), "SYNONYMS") and type eq "char";
       
        create table @dataset_work@
          as select 
            c.name as codelist_name,
            c.submissionValue as codelist_submissionValue,
            c.definition as codelist_definition,
            c.conceptId as codelist_conceptId,
            c.preferredTerm as codelist_preferredTerm,
            ifc(c.extensible = "true", "Yes", "No", "") as codelist_extensible length=3,   
            t.submissionValue as term_submissionValue,
            t.conceptId as term_conceptId,
            catx('; ', &synonym_variables) as term_synonyms length=1024,
            t.definition as term_definition,
            t.preferredTerm as term_preferredTerm
          from out.codelists c
        left join out.codelists_terms t
          on t.ordinal_codelists = c.ordinal_codelists
        left join out.terms_synonyms s
          on s.ordinal_terms = t.ordinal_terms;
      quit;    

      data @dataset_base@;
        set @dataset_base@ @dataset_work@;
      run;  
    ]], {dataset_base = "out."..example, dataset_work = "work."..example})

  endsubmit;
run;

proc lua;
  submit;
    local jf_json = require "jsonlibraries.jf_json"
    local json_string = fileutils.read('jsonfile')
    local json_table = jf_json:decode(json_string)
    local dsid = cdisclibrary.create_codelist_template (dataset_base.."_jf")
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
  endsubmit;
run;

proc lua;
  submit;
    local dk_json = require "jsonlibraries.dk_json"
    local json_string = fileutils.read('jsonfile')
    local json_table = dk_json.decode (json_string)
    local dsid = cdisclibrary.create_codelist_template (dataset_base.."_dk")
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
  endsubmit;
run;

proc lua;
  submit;
  	local dk_wiki_json = require "jsonlibraries.dk_wiki_json"
    local json_string = fileutils.read('jsonfile')
    local json_table = dk_wiki_json.decode(json_string)
    local dsid = cdisclibrary.create_codelist_template (dataset_base.."_dk_wiki")
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
  endsubmit;
run;

proc lua;
  submit;
  	local rxi_json = require "jsonlibraries.rxi_json"
    local json_string = fileutils.read('jsonfile')
    local json_table = rxi_json.decode(json_string)
    local dsid = cdisclibrary.create_codelist_template (dataset_base.."_rxi")
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
  endsubmit;
run;

proc lua;
  submit;
  	local luna_json = require "jsonlibraries.luna_json"
    local json_string = fileutils.read('jsonfile')
    local json_table = luna_json.decode(json_string)
    local dsid = cdisclibrary.create_codelist_template (dataset_base.."_luna")
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
  endsubmit;
run;

proc lua;
  submit;
    local libraries = {'jf', 'dk', 'dk_wiki', 'rxi', 'luna'}
    for index, lib in ipairs(libraries) do 
      
      sas.submit ([[
        proc compare base=@dataset_base@ compare=@dataset_comp@;
        run;
      ]], {dataset_base = "out."..example, dataset_comp = dataset_base.."_"..lib})
      if tonumber(sas.symget("sysinfo")) ~= 0 then 
        sas.print("%2zDifferences for "..dataset_base.."_"..lib)
      end

    end  
  endsubmit;
run;
