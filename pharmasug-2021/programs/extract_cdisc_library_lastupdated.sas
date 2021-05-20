%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;


filename luapath ("&project_folder/lua");
filename lastupd "&project_folder/response_json/_lastupdated_.json";


proc lua restart;
  submit;

    rest = require 'rest'
    json = require 'json'
    fileutils = require 'fileutils'
    
    local token = fileutils.read_config(sas.sysget('CREDENTIALS_FILE')).cdisclibrary.cdisc_api_primary_key
    rest.base_url = 'https://library.cdisc.org/api'
    rest.headers='"Accept"="application/json" "api-key"='..'"'..token..'"'

    local pass,code = rest.request('get','mdr/lastupdated', 'lastupd')
    local lastupdated = json:decode(rest.utils.read('lastupd'))

    local lastupdated_table={} 
    for key, value in pairs(lastupdated) do
      if key ~= "_links" then lastupdated_table[key] = value end
    end 

    print(table.tostring(lastupdated_table))

  endsubmit;
run;
