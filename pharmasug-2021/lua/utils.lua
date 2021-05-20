local utils={}
  
  function utils.tprint (tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\r\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
      toprint = toprint .. string.rep(" ", indent)
      if (type(k) == "number") then
        toprint = toprint .. "[" .. k .. "] = "
      elseif (type(k) == "string") then
        toprint = toprint  .. k ..  "= "   
      end
      if (type(v) == "number") then
        toprint = toprint .. v .. ",\r\n"
      elseif (type(v) == "string") then
        toprint = toprint .. "\"" .. v .. "\",\r\n"
      elseif (type(v) == "table") then
        toprint = toprint .. utils.tprint(v, indent + 2) .. ",\r\n"
      else
        toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
      end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
  end

  function utils.handle_failed_rest_response (message, response_file, header_file)
    
       print(message) 
       print(rest.utils.read(header_file))           
       if (sas.fileexists(response_file)) then 
         sas.filename('_temp_', response_file)
         print(rest.utils.read( '_temp_' ))           
         sas.io.delete(response_file) 
         sas.filename('_temp_')
       end
  end

return utils