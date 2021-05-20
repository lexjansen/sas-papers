%global project_folder;
%let project_folder=C:/_projects/sas-papers/pharmasug-2021;



options mprint;
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
    rest.quiet=false

    product_types = {
      'Foundational Model',
      'Implementation Guide',
      'Terminology'
      }
    extract_attributes = {
      {
        product_type = 'Foundational Model',
        table_postfix = '_class_tables',
        column_postfix = '_class_columns',
        template_tables = 'tmplts.tabulation_columnclassgroup',
        template_columns = 'tmplts.tabulation_columnclass',
        tabletype_tables = 'columnclassgroup',
        tabletype_columns = 'columnclass'
      },
      {
        product_type = 'Implementation Guide',
        table_postfix = '_ref_tables',
        column_postfix = '_ref_columns',
        template_tables = 'tmplts.tabulation_table',
        template_columns = 'tmplts.tabulation_column',
        tabletype_tables = 'table',
        tabletype_columns = 'column'
      },
      {}
    }

  endsubmit;
run;

proc lua;
  submit;

    local response_folder = sas.symget("response_folder")

    products = {'sdtm', 'sdtmig', 'sendig'}
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
    sas.where(dsid_prod, "productclass_title in ('Product Group Data Tabulation' 'Product Group Draft Content')") -- Only Tabulation

    while sas.next(dsid_prod) do
      -- loop over all products

      product_type = sas.get_value(dsid_prod,'product_type')
      product_href = sas.get_value(dsid_prod,'product_href')
      product = sas.scan(product_href, -2, '/')
      product_version = sas.scan(product_href, -1, '/')


      if _debug then
        print (product_type, product_href, product_version, product)
      end

      if (table.contains(products, product)) then
        -- only get the requested tabulation products

        print('>> ', product_type, product_href, product_version, product)

        sas.libname('extract', sas.symget("extract_folder").."/"..string.sub(product, 1, 4))

        local check, index = table.contains(product_types, product_type)

        if check then

          local response_file = sas.io.join(response_folder, product..'-'..product_version..'.json')
          sas.filename('response', response_file)
          local dataset_root = product..'_'..string.gsub(product_version, '-', '_')
          local output_dataset_tables = 'extract.'..dataset_root..extract_attributes[index].table_postfix
          local output_dataset_columns = 'extract.'..dataset_root..extract_attributes[index].column_postfix
          local lsaf_dataset_tables = product..'.'..dataset_root..extract_attributes[index].table_postfix
          local lsaf_dataset_columns = product..'.'..dataset_root..extract_attributes[index].column_postfix
          local template_tables = extract_attributes[index].template_tables
          local template_columns = extract_attributes[index].template_columns
          local tabletype_tables = extract_attributes[index].tabletype_tables
          local tabletype_columns = extract_attributes[index].tabletype_columns

          if (not sas.fileexists(response_file)) or
             (fileutils.lastmodified('response') < lastupdated['data-tabulation']) then
            local pass,code = rest.request('get',product_href, 'response')

            if not pass then
               utils.handle_failed_rest_response("ERR".."OR: extract failed.", response_file, '_hout_')
               goto next
            end   
          end
          local sdtm = json:decode(rest.utils.read('response'))


          if product_type == 'Foundational Model' then
            local dsid = cdisclibrary.tabulation_columnclassgroup(output_dataset_tables)
            cdisclibrary.add_tabulation_columnclassgroup_to_dataset (dsid, sdtm)
            if dsid then sas.close(dsid) end

            local dsid = cdisclibrary.tabulation_columnclass(output_dataset_columns)
            cdisclibrary.add_tabulation_columnclass_to_dataset (dsid, sdtm)
            if dsid then sas.close(dsid) end
          end

          if product_type == 'Implementation Guide' then
            local dsid = cdisclibrary.tabulation_table(output_dataset_tables)
            cdisclibrary.add_tabulation_table_to_dataset (dsid, sdtm)
            if dsid then sas.close(dsid) end

            local dsid = cdisclibrary.tabulation_column(output_dataset_columns)
            cdisclibrary.add_tabulation_column_to_dataset (dsid, sdtm)
            if dsid then sas.close(dsid) end
          end

          -- Map to LSAF ***
          sas.submit([[
            %map_extract_to_lsaf(
              mappingds=maps.mapping,
              tabletype=@tabletype@,
              template=@template@,
              source=@source@,
              target=@target@
              );
          ]], {tabletype=tabletype_tables, template=template_tables,
               source=output_dataset_tables, target=lsaf_dataset_tables}
          )

          sas.submit([[
            %map_extract_to_lsaf(
              mappingds=maps.mapping,
              tabletype=@tabletype@,
              template=@template@,
              source=@source@,
              target=@target@
              );
          ]], {tabletype=tabletype_columns, template=template_columns,
               source=output_dataset_columns, target=lsaf_dataset_columns}
          )

          sas.filename('response')
          sas.libname('extract')

        end -- check for product version type

        ::next::
        
      end

    end -- end of products loop
    if dsid_prod then sas.close(dsid_prod) end

    ::exit::

  endsubmit;
run;

data sdtm.sdtmig_3_2_ref_columns;
  set sdtm.sdtmig_3_2_ref_columns;
  if tablename="TR" and name="TRMETHOD" then submissiondatatype="Char";
run;
