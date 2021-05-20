local rest = require 'rest'
local json = require 'json'
local stringutils = require 'stringutils'

local cdisclibrary={}
  
  function cdisclibrary.lastupdated(fileref)
      
      local pass,code = rest.request('get','mdr/lastupdated', fileref)
      local lastupdated = json:decode(rest.utils.read(fileref))

      local lastupdated_table={} 
      for key, value in pairs(lastupdated) do
        if type(value) ~= 'table' then lastupdated_table[key] = value end
      end 
      
      return lastupdated_table
        
  end
    
  
  function cdisclibrary.products (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      {name="type", type="C", length=64, label="Product List Type"},
      {name="title", type="C", length=200, label="Product List Title"},
      {name="href", type="C", length=100, label="Product List Link"},
      {name="productclass_type", type="C", length=64, label="Product Class Type"},
      {name="productclass_title", type="C", length=200, label="Product Class Title"},
      {name="productclass_href", type="C", length=100, label="Product Class Link"},
      {name="product_type", type="C", length=100, label="Product Type"},
      {name="product_title", type="C", length=200, label="Product Title"},
      {name="product_href", type="C", length=64, label="Product Link"}
    })
    dsid = sas.open(dataset_name, "u")

    return dsid
  
  end
    
  function cdisclibrary.tabulation_table (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      { name="name", type="C", length=255},
      { name="label", type="C", length=1024},
      { name="description", type="C", length=2500},
      { name="effectiveDate", type="C", length=10},
      { name="registrationStatus", type="C", length=16},
      { name="version", type="C", length=20},
      { name="class_name", type="C", length=64},
      { name="table_ordinal", type="N"},
      { name="table_name", type="C", length=32},
      { name="table_label", type="C", length=256},
      { name="table_description", type="C", length=2500},
      { name="table_structure", type="C", length=1024},
    })
    dsid = sas.open(dataset_name, "u")
    return dsid
  
  end

  function cdisclibrary.tabulation_column (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      { name="name", type="C", length=255},
      { name="label", type="C", length=1024},
      { name="description", type="C", length=2500},
      { name="effectiveDate", type="C", length=10},
      { name="registrationStatus", type="C", length=16},
      { name="version", type="C", length=20},
      { name="table_name", type="C", length=32},
      { name="column_name", type="C", length=32},
      { name="column_label", type="C", length=256},
      { name="column_description", type="C", length=2500},
      { name="column_ordinal", type="N"},
      { name="column_role", type="C", length=64},      
      { name="column_simpleDatatype", type="C", length=32},
      { name="column_core", type="C", length=4},
      { name="codelistreference", type="C", length=64},
      { name="column_codelist", type="C", length=64},
      { name="column_valuelist", type="C", length=64},
      { name="column_describedvaluedomain", type="C", length=64},
      { name="classcolumn", type="C", length=32},
      { name="column_modelDatasetVariable", type="C", length=64},
      { name="column_modelClassVariable", type="C", length=64},
    })
    dsid = sas.open(dataset_name, "u")
    return dsid
  
  end

  function cdisclibrary.tabulation_columnclassgroup (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      { name="name", type="C", length=255},
      { name="label", type="C", length=1024},
      { name="description", type="C", length=2500},
      { name="effectiveDate", type="C", length=10},
      { name="registrationStatus", type="C", length=16},
      { name="version", type="C", length=20},
      { name="class_ordinal", type="N"},
      { name="class_name", type="C", length=255},
      { name="class_label", type="C", length=1024},
      { name="class_description", type="C", length=2500},
      { name="class_structure", type="C", length=1024},
      { name="dataset_name", type="C", length=255},
    })
    dsid = sas.open(dataset_name, "u")
    return dsid
  
  end

  function cdisclibrary.tabulation_columnclass (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      { name="name", type="C", length=255},
      { name="label", type="C", length=1024},
      { name="description", type="C", length=100},
      { name="effectiveDate", type="C", length=10},
      { name="registrationStatus", type="C", length=16},
      { name="version", type="C", length=20},
      { name="class_name", type="C", length=255},
      { name="dataset_name", type="C", length=255},
      { name="variable_ordinal", type="N"},
      { name="variable_name", type="C", length=32},
      { name="variable_label", type="C", length=256}, 
      { name="variable_description", type="C", length=2500}, 
      { name="variable_simpledatatype", type="C", length=32}, 
      { name="variable_role", type="C", length=64}, 
      { name="variable_roledescription", type="C", length=64}, 
      { name="variable_describedvaluedomain", type="C", length=64},
    })
    dsid = sas.open(dataset_name, "u")
    return dsid
  
  end


  function cdisclibrary.codelist (dataset_name)

    local dsid 
    
    sas.new_table(dataset_name, {
      { name="name", type="C", length=255},
      { name="label", type="C", length=1024},
      { name="description", type="C", length=2000},
      { name="effectiveDate", type="C", length=32},
      { name="registrationStatus", type="C", length=16},
      { name="version", type="C", length=20},
      { name="href", type="C", length=64},
      { name="codelist_submissionValue", type="C", length=70},
      { name="codelist_name", type="C", length=255, label="Codelist Name"},
      { name="codelist_definition", type="C", length=1024},
      { name="codelist_conceptId", type="C", length=8, label="Codelist Code"},
      { name="codelist_preferred_term", type="C", length=200},
      { name="codelist_synonyms", type="C", length=800},
      { name="codelist_extensible", type="C", length=3},
      { name="term_submissionValue", type="C", length=160, label="CDISC Submission Value"},      
      { name="term_conceptId", type="C", length=8, label="Code"},
      { name="term_synonyms", type="C", length=800},
      { name="term_definition", type="C", length=2000},
      { name="term_preferredTerm", type="C", length=200}
    })
    dsid = sas.open(dataset_name, "u")
    return dsid
  
  end


  function cdisclibrary.add_product_to_dataset (dsid, p)

    if dsid then

      for index, ProductClasses in pairs(p) do
        if _debug then print("ProductClasses  ", ">> ",index, ProductClasses, type(ProductClasses)) end
        for index, ProductClass in pairs(ProductClasses) do
          if _debug then print("ProductClass ", ">>>> ",index, ProductClass, type(ProductClass)) end
          if type(ProductClass)=="table" then
            for index, Products in pairs(ProductClass) do
              if _debug then print("Products ", ">>>>>> ",index, Products, type(Products)) end
              if type(Products)=="table" then
                for index, Product in pairs(Products) do
                  if Product.href ~= nil then
                    if _debug then print("Product ", ">>>>>>>> ",index, Product.href) end
                    sas.append(dsid)

                    sas.put_value(dsid, "type", p.self.type)
                    sas.put_value(dsid, "title", p.self.title)
                    sas.put_value(dsid, "href", p.self.href)

                    sas.put_value(dsid, "productclass_type", ProductClass.self.type)
                    sas.put_value(dsid, "productclass_title", ProductClass.self.title)
                    sas.put_value(dsid, "productclass_href", ProductClass.self.href)

                    sas.put_value(dsid, "product_type", Product.type)
                    sas.put_value(dsid, "product_title", Product.title)
                    sas.put_value(dsid, "product_href", Product.href)

                    sas.update(dsid)
                  end
                end
              end
            end
          end
        end
      end

      return true
    else 
      return false
    end  
  end
  
  
  function cdisclibrary.add_tabulation_table_to_dataset (dsid, sdtmig)
	  
    if dsid then
  	  local classes = sdtmig.classes
  	  for index, data in pairs(classes) do
  	    local datasets = data.datasets
  	      if datasets then
  	        for index2, data2 in pairs(datasets) do
  	        
            sas.append(dsid)
  
            sas.put_value(dsid, "name", sdtmig.name)
            sas.put_value(dsid, "label", sdtmig.label)
            sas.put_value(dsid, "description", sdtmig.description)
            sas.put_value(dsid, "effectiveDate", sdtmig.effectiveDate)
            sas.put_value(dsid, "registrationStatus", sdtmig.registrationStatus)
            sas.put_value(dsid, "version", sdtmig.version)
            
            sas.put_value(dsid, "class_name", data.name)
            if tonumber(data2.ordinal) ~= nil then sas.put_value(dsid, "table_ordinal", data2.ordinal) end
            sas.put_value(dsid, "table_name", data2.name)
            sas.put_value(dsid, "table_label", data2.label)
            sas.put_value(dsid, "table_description", data2.description)
            sas.put_value(dsid, "table_structure", data2.datasetStructure)
  
            sas.update(dsid)
    	    end
    	end
    end
      return true
  	else 
      return false
    end
  
  end


  function cdisclibrary.add_tabulation_column_to_dataset (dsid, sdtmig)
	  
    if dsid then
  	  local classes = sdtmig.classes
  	  for index, data in pairs(classes) do
  	    local datasets = data.datasets
  	      if datasets then
  	        for index2, data2 in pairs(datasets) do
              local datasetVariables = data2.datasetVariables
                if datasetVariables then  
                  for index3, data3 in pairs(datasetVariables) do 	      
  	        
                    sas.append(dsid)
          
                    sas.put_value(dsid, "name", sdtmig.name)
                    sas.put_value(dsid, "label", sdtmig.label)
                    sas.put_value(dsid, "description", sdtmig.description)
                    sas.put_value(dsid, "effectiveDate", sdtmig.effectiveDate)
                    sas.put_value(dsid, "registrationStatus", sdtmig.registrationStatus)
                    sas.put_value(dsid, "version", sdtmig.version)
                    
                    sas.put_value(dsid, "table_name", data2.name)

                    sas.put_value(dsid, "column_name", data3.name)
                    sas.put_value(dsid, "column_label", data3.label)
                    sas.put_value(dsid, "column_description", data3.description)
                    if tonumber(data3.ordinal) ~= nil then sas.put_value(dsid, "column_ordinal", data3.ordinal) end
                    sas.put_value(dsid, "column_role", data3.role)
                    sas.put_value(dsid, "column_simpledatatype", data3.simpleDatatype)
                    sas.put_value(dsid, "column_core", data3.core)
                    
                    local codelist_val
                    if data3._links.codelist ~= nil then
                      local codelist_table = data3._links.codelist
                      -- print("==> ", sdtmig.name, data2.name, data3.name, #codelist_table, table.tostring(codelist_table) )
                      if #codelist_table > 0 then
                        local codelist = stringutils.strSplit("/", data3._links.codelist[1].href)
                        codelist_val = codelist[#codelist] 
                        for i=2,10 do
                          if data3._links.codelist[i] ~= nil then
                             codelist = stringutils.strSplit("/", data3._links.codelist[i].href) 
                             codelist_val = codelist_val..", "..codelist[#codelist]
                             print("WARNING: multiple codelists --> ", data3._links.parentProduct.href, data2.name, data3.name, codelist_val)
                          end
                        end
                        sas.put_value(dsid, "column_codelist", codelist_val)
                      end  
                    end
                    
                    if data3.valueList then
                      sas.put_value(dsid, "column_valuelist", table.concat(data3.valueList,", ")) 
                    end
                    
                    sas.put_value(dsid, "column_describedvaluedomain", data3.describedValueDomain)
                    
                    if data3._links.modelDatasetVariable ~= nil then
                      -- local modelDatasetVariable = stringutils.strSplit("/", data3._links.modelDatasetVariable.href) 
                      -- sas.put_value(dsid, "classcolumn", modelDatasetVariable[#modelDatasetVariable])
                      sas.put_value(dsid, "column_modeldatasetvariable", data3._links.modelDatasetVariable.href)
                    end  
                    if data3._links.modelClassVariable ~= nil then
                      -- local modelClassVariable = stringutils.strSplit("/", data3._links.modelClassVariable.href) 
                      -- sas.put_value(dsid, "classcolumn", modelClassVariable[#modelClassVariable])
                      sas.put_value(dsid, "column_modelclassvariable", data3._links.modelClassVariable.href)
                    end  
          
                    sas.update(dsid)

                  end
                end
            end
    	    end
    	end
      return true
  	else 
      return false
    end
  
  end


  function cdisclibrary.add_tabulation_columnclassgroup_to_dataset (dsid, sdtm)
	  
    if dsid then

  	  local classes = sdtm.classes
  	  
  	  for index, data in pairs(classes) do
            sas.append(dsid)
            sas.put_value(dsid, "name", sdtm.name)
            sas.put_value(dsid, "label", sdtm.label)
            sas.put_value(dsid, "description", sdtm.description)
            sas.put_value(dsid, "effectiveDate", sdtm.effectiveDate)
            sas.put_value(dsid, "registrationStatus", sdtm.registrationStatus)
            sas.put_value(dsid, "version", sdtm.version)
            
            if tonumber(data.ordinal) ~= nil then sas.put_value(dsid, "class_ordinal", data.ordinal) end
            sas.put_value(dsid, "class_name", data.name)
            sas.put_value(dsid, "class_label", data.label)
            sas.put_value(dsid, "class_description", data.description)
            sas.put_value(dsid, "class_structure", data.datasetStructure)
  
            sas.update(dsid)
  	  end

  	  local classes = sdtm.classes
  	  for index, data in pairs(classes) do
        local datasets = data.datasets
        if datasets then
          for index2, data2 in pairs(datasets) do
  	    
            sas.append(dsid)
  
            sas.put_value(dsid, "name", sdtm.name)
            sas.put_value(dsid, "label", sdtm.label)
            sas.put_value(dsid, "description", sdtm.description)
            sas.put_value(dsid, "effectiveDate", sdtm.effectiveDate)
            sas.put_value(dsid, "registrationStatus", sdtm.registrationStatus)
            sas.put_value(dsid, "version", sdtm.version)
            
            if tonumber(data.ordinal) ~= nil then sas.put_value(dsid, "class_ordinal", data.ordinal) end
            -- sas.put_value(dsid, "class_name", data2._links.parentClass.title)
            sas.put_value(dsid, "class_name", data.name)
            sas.put_value(dsid, "class_label", data2.label)
            sas.put_value(dsid, "class_description", data2.description)
            sas.put_value(dsid, "class_structure", data2.datasetStructure)
            sas.put_value(dsid, "dataset_name", data2.name)
  
            sas.update(dsid)
            
          end  
        end    
  	  end

      return true
  	else 
      return false
    end
  
  end


  function cdisclibrary.add_tabulation_columnclass_to_dataset (dsid, sdtm)
	  
    if dsid then
      
  	  local classes = sdtm.classes
  	  
  	  for index, data in pairs(classes) do
        local classVariables = data.classVariables
        if classVariables then
          for index2, data2 in pairs(classVariables) do
            sas.append(dsid)
  
            sas.put_value(dsid, "name", sdtm.name)
            sas.put_value(dsid, "label", sdtm.label)
            sas.put_value(dsid, "description", sdtm.description)
            sas.put_value(dsid, "effectiveDate", sdtm.effectiveDate)
            sas.put_value(dsid, "registrationStatus", sdtm.registrationStatus)
            sas.put_value(dsid, "version", sdtm.version)
            
            sas.put_value(dsid, "class_name", data.name)
            -- sas.put_value(dsid, "dataset_name", data.name)
            if tonumber(data2.ordinal) ~= nil then sas.put_value(dsid, "variable_ordinal", data2.ordinal) end
            sas.put_value(dsid, "variable_name", data2.name)
            sas.put_value(dsid, "variable_label", data2.label)
            sas.put_value(dsid, "variable_description", data2.description)
            sas.put_value(dsid, "variable_simpledatatype", data2.simpleDatatype)
            sas.put_value(dsid, "variable_role", data2.role)
            sas.put_value(dsid, "variable_roledescription", data2.roleDescription)
            sas.put_value(dsid, "variable_describedvaluedomain", data2.describedValueDomain)
  
            sas.update(dsid)
          end   
        end
      end
        
  	  for index, data in pairs(classes) do
        local datasets = data.datasets
        if datasets then
          for index2, data2 in pairs(datasets) do
            local datasetVariables = data2.datasetVariables
            if datasetVariables then
              for index3, data3 in pairs(datasetVariables) do

                sas.append(dsid)
      
                sas.put_value(dsid, "name", sdtm.name)
                sas.put_value(dsid, "label", sdtm.label)
                sas.put_value(dsid, "description", sdtm.description)
                sas.put_value(dsid, "effectiveDate", sdtm.effectiveDate)
                sas.put_value(dsid, "registrationStatus", sdtm.registrationStatus)
                sas.put_value(dsid, "version", sdtm.version)
                
                -- sas.put_value(dsid, "class_name", data2._links.parentClass.title)
                sas.put_value(dsid, "class_name", data.name)
                sas.put_value(dsid, "dataset_name", data2.name)
                if tonumber(data3.ordinal) ~= nil then sas.put_value(dsid, "variable_ordinal", data3.ordinal) end
                sas.put_value(dsid, "variable_name", data3.name)
                sas.put_value(dsid, "variable_label", data3.label)
                sas.put_value(dsid, "variable_description", data3.description)
                sas.put_value(dsid, "variable_simpledatatype", data3.simpleDatatype)
                sas.put_value(dsid, "variable_role", data3.role)
                sas.put_value(dsid, "variable_roledescription", data3.roleDescription)
                sas.put_value(dsid, "variable_describedvaluedomain", data3.describedValueDomain)
      
                sas.update(dsid)

              end
            end  
          end   
        end
      end

      return true
  	else 
      return false
    end
  
  end


  function cdisclibrary.add_codelist_to_dataset (dsid, package)
	  
    if dsid then
  	  local codelists = package.codelists
  	  for index, data in pairs(codelists) do
        local terms = data.terms
        if terms then 
          for index2, data2 in pairs(terms) do
            sas.append(dsid)

            sas.put_value(dsid, "name", package.name)
            sas.put_value(dsid, "label", package.label)
            sas.put_value(dsid, "description", package.description)
            sas.put_value(dsid, "effectiveDate", package.effectiveDate)
            sas.put_value(dsid, "registrationStatus", package.registrationStatus)
            sas.put_value(dsid, "version", package.version)
            sas.put_value(dsid, "href", package._links.self.href)
            
            sas.put_value(dsid, "codelist_name", data.name)
            sas.put_value(dsid, "codelist_submissionValue", data.submissionValue)
            sas.put_value(dsid, "codelist_definition", data.definition)
            sas.put_value(dsid, "codelist_conceptId", data.conceptId)

            sas.put_value(dsid, "codelist_preferred_term", data.preferredTerm)
            if data.synonyms then sas.put_value(dsid, "codelist_synonyms", table.concat(data.synonyms, "; ")) end

            local extensible = ""
            if data.extensible == "true" then
              extensible = "Yes"
            else
              extensible = "No"
            end  
            sas.put_value(dsid, "codelist_extensible", extensible)
            
            sas.put_value(dsid, "term_submissionValue", data2.submissionValue)
            
            local l1 = sas.varlen(dsid, "term_submissionValue")
            local l2 = string.len(data2.submissionValue)
            if l2 > l1 then 
              sas.print("%1zValue = %s (length=%s) does not fit in variable %s (length=%s)", 
                data2.submissionValue, 
                tostring(string.len(data2.submissionValue)),
                sas.varname(dsid, "term_submissionValue"), 
                tostring(sas.varlen(dsid, "term_submissionValue"))
                )
                
            end;
          
            sas.put_value(dsid, "term_conceptId", data2.conceptId)
            sas.put_value(dsid, "term_preferredTerm", data2.preferredTerm)
            sas.put_value(dsid, "term_definition", data2.definition)
            if data2.synonyms then sas.put_value(dsid, "term_synonyms", table.concat(data2.synonyms, "; ")) end

            sas.update(dsid)
          end        
        end
  	  end
      return true
  	else 
      return false
    end
  
  end
  
  
  return cdisclibrary
