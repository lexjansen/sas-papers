%global root;
%let root=/_projects/sas-papers/phuse_eu-2021;

filename luapath ("&root/lua" "&root/lua/jsonlibraries");

proc lua restart;
  submit;

    local fileutils = require 'fileutils'
    local rest = require 'rest'
    local cdisclibrary = require 'cdisclibrary'
    local jf_json = require 'jsonlibraries.jf_json'

    sas.gfilename('jsonfile', sas.symget("root")..'/json/sdtmct_20210625.json')
    
    rest.base_url = 'https://library.cdisc.org/api'
    -- provide your own CDISC library API key
    local token = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    -- local token = fileutils.read_config('credentials.cfg').cdisclibrary.cdisc_api_primary_key
    rest.headers='"Accept"="application/json" "api-key"='..'"'..token..'"'
    
    local pass,code = rest.request('get', '/mdr/ct/packages/sdtmct-2021-06-25', 'jsonfile')
    
    local json_string = fileutils.read('jsonfile')
    local json_table = jf_json:decode(json_string)

    local dsid = cdisclibrary.create_codelist_template('work.sdtmct_20210625')
    cdisclibrary.codelists_lua2sas(dsid, json_table)
    sas.close(dsid)
    
  endsubmit;
run;
