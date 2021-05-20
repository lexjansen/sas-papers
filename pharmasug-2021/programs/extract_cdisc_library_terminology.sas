%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;




%* Generic configuration;
%include "&project_folder/programs/config.sas";

%let _debug=0;

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
    rest.debug = sas.symget("rest_debug")

    -- Setting to false will reveal PROC HTTP statement in the LOG with username/password !!
    rest.quiet=true

  endsubmit;
run;

proc lua;
  submit;

    local response_folder = sas.symget("response_folder")
    sas.glibname('extract', sas.symget("extract_folder").."/ct")

    -- startdate = '20210301'
    -- products = {'cdashct', 'define-xmlct', 'sdtmct', 'sendct'}
    startdate = '20201106'
    products = {'adamct'}
    products_dataset = "prod.products"

    if not sas.exists(products_dataset) then
      print("ERR".."OR: dataset "..products_dataset.." not found.")
      goto exit
    end

    ----------------------------------------------------------------------------------------------------------------------
    --- LASTUPDATED
    ----------------------------------------------------------------------------------------------------------------------
    sas.filename('lastupd', sas.io.join(response_folder, "_lastupdated_.json"))
    local lastupdated = cdisclibrary.lastupdated('lastupd')
    sas.filename('lastupd')
    print(utils.tprint (lastupdated, 0))

    local dsid_prod = sas.open(products_dataset)
    sas.where(dsid_prod, "productclass_title = 'Product Group Terminology'") -- Only Terminology

    while sas.next(dsid_prod) do
      -- loop over all products

      product_type = sas.get_value(dsid_prod,'product_type')
      product_href = sas.get_value(dsid_prod,'product_href')
      product = sas.scan(product_href, -1, '/')
      pubdate = string.gsub(string.sub(product, string.len(product)-9), '-', '')
      ctproduct = string.sub(product, 1, string.len(product)-11)

      if _debug then
        print (startdate, product_type, product_href, product, ctproduct, pubdate)
      end

      if (table.contains(products, ctproduct))  and (pubdate >= startdate) then
        -- only get the requested terminology products after the start date

        print('>> ', startdate, product_type, product_href, product, ctproduct, pubdate)

        local response_file = sas.io.join(response_folder, ctproduct..'_'..pubdate..'.json')
        sas.filename('cdisc_ct', response_file)
        local output_dataset = 'extract.'..string.gsub(ctproduct, '-', '_')..'_'..pubdate
        local lsaf_dataset = 'ct.'..string.gsub(ctproduct, '-', '_')..'_'..pubdate

        ----------------------------------------------------------------------------------------------------------------------
        --- GET CT
        ----------------------------------------------------------------------------------------------------------------------
        if (not sas.fileexists(response_file)) or
           (fileutils.lastmodified('cdisc_ct') < lastupdated['terminology']) then
          print('>>>> extract ', product_href, product, ctproduct, pubdate)
          local pass,code = rest.request('get', product_href, 'cdisc_ct')

          if not pass then
             utils.handle_failed_rest_response("ERR".."OR: extract failed.", response_file, '_hout_')
             goto next
          end
        end
        local ctpackage = json:decode(rest.utils.read('cdisc_ct'))

        local dsid = cdisclibrary.codelist(output_dataset)
        cdisclibrary.add_codelist_to_dataset (dsid, ctpackage)
        if dsid then sas.close(dsid) end

        -- Map Code Lists to LSAF ***;
        sas.submit([[
          %map_extract_to_lsaf(
            mappingds=maps.mapping,
            tabletype=codelist,
            template=tmplts.terminology,
            source=@source@,
            target=@target@
            );
        ]], {source=output_dataset, target=lsaf_dataset})

      end

      ::next::
      sas.filename('cdisc_ct')

    end -- end of products loop
    if dsid_prod then sas.close(dsid_prod) end

    ::exit::

  endsubmit;
run;
