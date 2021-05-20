local fileutils={}
  

function fileutils.lastmodified(fileref)
  
   if type(fileref) == "string" then
       fileref =  sasxx.new(fileref)
   end
   local path = fileref:info().path   
   if not path then
      fileref:deassign()
      return nil, "ERROR: Couldn't open file referenced by "..tostring(fileref).." for read."   
   end

   local lastmodified = ""
   
   logical = sasxx.assign(path)
   d = logical:info().lastmod

   local months = {jan='01', feb='02', mar='03', apr='04', may='05', jun='06', jul='07', aug='08', sep='09', oct='10', nov='11', dec='12'} 

   local day, month, year, time = d:match('^(%d%d)(%D%D%D)(%d%d%d%d):(.*)$')
   local lastmodified = year.."-"..months[month].."-"..day
      
   return lastmodified,""  

end

function file_exists(path)
  local f = io.open(path)
  if f == nil then return end
  f:close()
  return path
end

--------------------------------------------------------------------------------
-- Read the whole configuration in a table such that each section is a key to
-- key/value pair table containing the corresponding pairs from the file.
-- Optionally limit to a section

function fileutils.read_config(filename)
  filename = filename or ''
  assert(type(filename) == 'string')
  local ans,u,k,v,temp = {}
  if not file_exists(filename) then return ans end
  for line in io.lines(filename) do
    temp = line:match('^%[(.+)%]$')  -- section
    if temp ~= nil and u ~= temp then u = temp end
    k,v = line:match('^([^#=]+)=(.+)$')
    if u ~= nil then
      ans[u] = ans[u] or {}
      if k ~= nil then
        ans[u][k] = v
      end
    end
  end
  return ans
end


return fileutils