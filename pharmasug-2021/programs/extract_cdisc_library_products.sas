%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;




%* Generic configuration;
%include "&project_folder/programs/config.sas";

%let _debug=0;
%let rest_debug=%str(OUTPUT_TEXT REQUEST_HEADERS NO_REQUEST_BODY RESPONSE_HEADERS NO_RESPONSE_BODY);

proc lua restart;
  submit;
    print(_VERSION)

    rest = require 'rest'
    json = require 'json'
    cdisclibrary = require 'cdisclibrary'
    fileutils = require 'fileutils'
    utils = require 'utils'

    _debug = sas.symget("_debug") == 1
    sas.set_quiet(false)

    local token = fileutils.read_config(sas.symget('credentials_file')).cdisclibrary.cdisc_api_primary_key

    rest.base_url = sas.symget("base_url")
    rest.headers='"Accept"="application/json" "api-key"='..'"'..token..'"'
    rest.proxyhost=sas.symget("rest_proxyhost")
    rest.proxyport=sas.symget("rest_proxyport")
    rest.timeout = sas.symget("rest_timeout")
    -- rest.debug = sas.symget("rest_debug")

    -- Setting to false will reveal PROC HTTP statement in the LOG with username/password !!
    rest.quiet=true

  endsubmit;
run;


proc lua;
  submit;

    local response_folder = sas.symget("response_folder")
    local response_file = sas.io.join(response_folder, "_products.json")
    local products_dataset = "prod.products"

    ----------------------------------------------------------------------------------------------------------------------
    --- LASTUPDATED
    ----------------------------------------------------------------------------------------------------------------------
    
    sas.filename('lastupd', sas.io.join(response_folder, "_lastupdated_.json"))
    local lastupdated = cdisclibrary.lastupdated('lastupd')
    sas.filename('lastupd')
    print(utils.tprint (lastupdated, 0))

    ----------------------------------------------------------------------------------------------------------------------
    --- PRODUCTS
    ----------------------------------------------------------------------------------------------------------------------


    sas.filename('products', response_file)

    if (not sas.fileexists(response_file)) or
       (fileutils.lastmodified('products') < lastupdated['overall']) then
      local pass,code = rest.request('get','mdr/products', 'products')
      if not pass then
        utils.handle_failed_rest_response("ERR".."OR: extract failed.", response_file, '_hout_')
        goto exit
      end      
    end
    cdisc_products = json:decode(rest.utils.read('products'))._links

    if _debug then print(utils.tprint (cdisc_products, 0)) end

    dsid = cdisclibrary.products(products_dataset)
    cdisclibrary.add_product_to_dataset (dsid, cdisc_products)
    if dsid then sas.close(dsid) end
    
    sas.submit([[
          proc sort data=@dataset@;
            by @sort_key@;
          run;
    ]], { dataset=products_dataset, sort_key="product_href" })

    ::exit::
  
    sas.filename('products')

  endsubmit;
run;


ods listing close;
ods html path="&project_folder/programs" file="extract_cdisc_library_products.html";

  proc print data=prod.products;
  title "CDISC Library Products %sysfunc(date(), e8601da10.)";
  run;

  proc contents data=prod.products varnum;
  run;

ods html close;
ods listing;
