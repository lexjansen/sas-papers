local cdisclibrary={}

  function cdisclibrary.create_codelist_template (dataset_name)

    sas.new_table(dataset_name, {
        { name="codelist_name", type="C", length=256, label="Codelist Name"},
        { name="codelist_submissionValue", type="C", length=128, label="CDISC Submission Value"},
        { name="codelist_definition", type="C", length=1024, label="Codelist Definition"},
        { name="codelist_conceptId", type="C", length=8, label="Codelist Code"},
        { name="codelist_preferredTerm", type="C", length=256, label="Codelist Preferred Term"},
        { name="codelist_extensible", type="C", length=8, label="Codelist Extensible"},
        { name="term_submissionValue", type="C", length=256, label="CDISC Submission Value"},
        { name="term_conceptId", type="C", length=8, label="Term Code"},
        { name="term_synonyms", type="C", length=1024, label="Term Synonyms"},
        { name="term_definition", type="C", length=2048, label="Term Definition"},
        { name="term_preferredTerm", type="C", length=512, label="Preferred Term"}
    })
    
    local dsid = sas.open(dataset_name, "u")
    return dsid
    
  end
  
  function map_extensible(v) 
    if v == "true" then return "Yes" else return "No" end
  end

  function cdisclibrary.codelists_lua2sas(dsid, lua_table)
    
    local codelists = lua_table.codelists
    for index, codelist in pairs(codelists) do
      local terms = codelist.terms
      if terms then
        for index2, term in pairs(terms) do
          sas.append(dsid)

          sas.put_value(dsid, "codelist_name", codelist.name)
          sas.put_value(dsid, "codelist_submissionValue", codelist.submissionValue)
          sas.put_value(dsid, "codelist_definition", codelist.definition)
          sas.put_value(dsid, "codelist_conceptId", codelist.conceptId)
          sas.put_value(dsid, "codelist_preferredTerm", codelist.preferredTerm)
          sas.put_value(dsid, "codelist_extensible", map_extensible(codelist.extensible))
          sas.put_value(dsid, "term_submissionValue", term.submissionValue)
          sas.put_value(dsid, "term_conceptId", term.conceptId)
          if term.synonyms then sas.put_value(dsid, "term_synonyms", table.concat(term.synonyms, "; ")) end
          sas.put_value(dsid, "term_preferredTerm", term.preferredTerm)
          sas.put_value(dsid, "term_definition", term.definition)

          sas.update(dsid)
        end
      end
    end
    return true
  end

return cdisclibrary

